class Application < ApplicationRecord
  # These columns are no longer populated with data for future applications
  # but are still in place because they contain historical data.
  # This constant is set so that despite still existing they won't be hooked up
  # within the rails model
  self.ignored_columns = %w[DEPRECATED_cohort]

  belongs_to :user
  belongs_to :course
  belongs_to :lead_provider
  belongs_to :school, foreign_key: "school_urn", primary_key: "urn", optional: true
  belongs_to :private_childcare_provider, foreign_key: "private_childcare_provider_urn", primary_key: "provider_urn", optional: true

  has_many :ecf_sync_request_logs, as: :syncable, dependent: :destroy


  scope :unsynced, -> { where(ecf_id: nil) }

  enum kind_of_nursery: {
    local_authority_maintained_nursery: "local_authority_maintained_nursery",
    preschool_class_as_part_of_school: "preschool_class_as_part_of_school",
    private_nursery: "private_nursery",
    another_early_years_setting: "another_early_years_setting",
  }

  def synced_to_ecf?
    ecf_id.present?
  end

  def inside_catchment?
    %w[england].include?(teacher_catchment)
  end

  def new_headteacher?
    %w[yes_when_course_starts yes_in_first_five_years yes_in_first_two_years].include?(headteacher_status)
  end

  def school
    School.find_by(urn: school_urn)
  end

  def receive_lead_provider_approval_status_from_ecf
    uri = URI.parse("#{ENV['ECF_APP_BASE_URL']}/api/v3/npq-applications/send_lead_provider_approval_status_to_npq")
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{ENV['ECF_APP_BEARER_TOKEN']}"

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      response_data = JSON.parse(response.body)
      filtered_applications = Application.where.not(ecf_id: nil)

      response_data["data"].map do |status_data| 
        retrieved_id = status_data["attributes"]["id"]
        retrieved_status = status_data["attributes"]["lead_provider_approval_status"]
        application = filtered_applications.find_by(ecf_id: retrieved_id)
        application.update!(lead_provider_approval_status: retrieved_status) if application.present?
      end
    end
  end
end
