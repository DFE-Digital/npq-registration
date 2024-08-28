require "qualified_teachers"

class QualifiedTeachersAPISender
  include ActiveModel::Model
  include ActiveModel::Attributes
  include CourseHelper

  SUCCESS_CODES = %w[204].freeze

  attribute :participant_outcome_id

  validates :participant_outcome_id, presence: true
  validates :participant_outcome, presence: true
  validate :not_already_sent

  def send_record
    set_sent_to_qualified_teachers_api_at

    return if invalid?

    create_participant_outcome_api_request!
    set_qualified_teachers_api_request_successful
    participant_outcome
  end

  def participant_outcome
    @participant_outcome ||= ParticipantOutcome.includes(declaration: { application: :user }).find_by(id: participant_outcome_id)
  end

private

  def not_already_sent
    return if participant_outcome&.qualified_teachers_api_request_successful.nil?

    errors.add(:participant_outcome, :already_successfully_sent_to_api) if participant_outcome&.qualified_teachers_api_request_successful?
    errors.add(:participant_outcome, :already_unsuccessfully_sent_to_api) if participant_outcome&.qualified_teachers_api_request_successful == false
  end

  def set_sent_to_qualified_teachers_api_at
    participant_outcome.update(
      sent_to_qualified_teachers_api_at: Time.zone.now,
    )
  end

  def create_participant_outcome_api_request!
    participant_outcome.participant_outcome_api_requests.create!(
      request_path: api_response.response.uri.to_s,
      status_code: api_response.response.code,
      request_headers: api_response.request.each_header.to_h.except("authorization"),
      request_body: request_body.stringify_keys,
      response_headers: api_response.response.each_header.to_h,
      response_body: response_body(api_response.response.body),
      ecf_id: SecureRandom.uuid,
    )
  rescue StandardError => e
    Rails.logger.warn(e.message)
    Sentry.capture_exception(e)
  end

  def set_qualified_teachers_api_request_successful
    participant_outcome.update(
      qualified_teachers_api_request_successful: SUCCESS_CODES.include?(api_response.response.code),
    )
  end

  def qualified_teachers_client
    @qualified_teachers_client ||= QualifiedTeachers::Client.new
  end

  def request_body
    @request_body ||= {
      completionDate: completion_date,
      qualificationType: participant_outcome.declaration.course.short_code,
    }
  end

  def completion_date
    participant_outcome.completion_date.to_s if participant_outcome.passed_state?
  end

  def trn
    @trn ||= participant_outcome.declaration&.user&.trn
  end

  def api_response
    @api_response ||= qualified_teachers_client.send_record(trn:, request_body:)
  end

  def response_body(response_data)
    return if response_data.blank?

    JSON.parse(response_data)
  rescue JSON::ParserError
    { error: "response data did not contain valid JSON" }
  end
end
