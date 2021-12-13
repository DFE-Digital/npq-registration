require "active_support/time"

class RegistrationWizard
  include ActiveModel::Model
  include Forms::Helpers::Institution
  include ActionView::Helpers::TranslationHelper

  class InvalidStep < StandardError; end

  attr_reader :current_step, :params, :store, :request

  def initialize(current_step:, store:, request:, params: {})
    set_current_step(current_step)
    @params = params
    @store = store
    @request = request
  end

  def self.permitted_params_for_step(step)
    "Forms::#{step.to_s.camelcase}".constantize.permitted_params
  end

  def before_render
    form.before_render
  end

  def after_render
    form.after_render
  end

  def session
    request.session
  end

  def form
    return @form if @form

    hash = load_from_store
    hash.merge!(params)
    hash.merge!(wizard: self)

    @form ||= form_class.new(hash)
  end

  def save!
    form.attributes.each do |k, v|
      store[k.to_s] = v
    end

    form.after_save
  end

  def next_step_path
    form.next_step.to_s.dasherize
  end

  def previous_step_path
    form.previous_step.to_s.dasherize
  end

  def answers
    dob = Forms::QualifiedTeacherCheck.new(store.select { |k, _v| k.starts_with?("date_of_birth") }).date_of_birth
    array = []

    array << OpenStruct.new(key: "Where do you work?",
                            value: query_store.where_teach_humanized,
                            change_step: :teacher_catchment)

    array << OpenStruct.new(key: "Do you work in a school or college?",
                            value: store["works_in_school"].capitalize,
                            change_step: :work_in_school)

    array << OpenStruct.new(key: "Full name",
                            value: store["full_name"],
                            change_step: :qualified_teacher_check)

    array << OpenStruct.new(key: "TRN",
                            value: store["trn"],
                            change_step: :qualified_teacher_check)

    begin
      array << OpenStruct.new(key: "Date of birth",
                              value: dob.to_s(:govuk),
                              change_step: :qualified_teacher_check)
    rescue ArgumentError => e
      Sentry.capture_exception(e, extra: { dob: dob })

      raise e
    end

    if form_for_step(:qualified_teacher_check).national_insurance_number.present?
      array << OpenStruct.new(key: "National Insurance number",
                              value: store["national_insurance_number"],
                              change_step: :qualified_teacher_check)
    end

    array << OpenStruct.new(key: "Email",
                            value: store["confirmed_email"],
                            change_step: :contact_details)

    if query_store.inside_catchment? && query_store.works_in_school?
      array << OpenStruct.new(key: "School or college",
                              value: institution(source: store["institution_identifier"]).name,
                              change_step: :find_school)
    end

    array << OpenStruct.new(key: "Course",
                            value: query_store.course.name,
                            change_step: :choose_your_npq)

    if needs_funding?
      array << if course.aso?
                 OpenStruct.new(key: "How is the Additional Support Offer being paid for?",
                                value: I18n.t(store["aso_funding_choice"], scope: "activemodel.attributes.forms/funding_your_aso.funding_options"),
                                change_step: :funding_your_aso)
               else
                 OpenStruct.new(key: "How is your NPQ being paid for?",
                                value: I18n.t(store["funding"], scope: "activemodel.attributes.forms/funding_your_npq.funding_options"),
                                change_step: :funding_your_npq)
               end
    end

    array << OpenStruct.new(key: "Lead provider",
                            value: query_store.lead_provider.name,
                            change_step: :choose_your_provider)

    unless query_store.works_in_school?
      array << OpenStruct.new(key: "Employer",
                              value: store["employer_name"],
                              change_step: :your_work)
      array << OpenStruct.new(key: "Role",
                              value: store["employment_role"],
                              change_step: :your_work)
    end

    array
  end

  def form_for_step(step)
    form_class = "Forms::#{step.to_s.camelcase}".constantize
    hash = store.slice(*form_class.permitted_params.map(&:to_s))
    hash.merge!(wizard: self)
    form_class.new(hash)
  end

  def query_store
    @query_store ||= Services::QueryStore.new(store: store)
  end

private

  def needs_funding?
    !Services::FundingEligibility.new(
      course: course,
      institution: institution(source: store["institution_identifier"]),
      new_headteacher: new_headteacher?,
    ).call
  end

  def new_headteacher?
    store["aso_headteacher"] == "yes" && store["aso_new_headteacher"] == "yes"
  end

  def course
    Course.find(store["course_id"])
  end

  def load_from_store
    store.slice(*form_class.permitted_params.map(&:to_s))
  end

  def form_class
    @form_class ||= "Forms::#{current_step.to_s.camelcase}".constantize
  end

  def set_current_step(step)
    @current_step = steps.find { |s| s == step.to_sym }

    raise InvalidStep, "Could not find step: #{step}" if @current_step.nil?
  end

  def steps
    %i[
      start
      teacher_catchment
      work_in_school
      provider_check
      about_npq
      teacher_reference_number
      change_dqt
      dont_know_teacher_reference_number
      dont_have_teacher_reference_number
      contact_details
      confirm_email
      resend_code
      qualified_teacher_check
      not_sure_updated_name
      dqt_mismatch
      about_aso
      npqh_status
      aso_unavailable
      aso_headteacher
      aso_new_headteacher
      aso_funding_not_available
      aso_possible_funding
      aso_funding_contact
      funding_your_aso
      choose_your_npq
      choose_your_provider
      find_school
      choose_school
      your_work
      school_not_in_england
      possible_funding
      funding_your_npq
      share_provider
      check_answers
      confirmation
    ]
  end

  def submission_params
    params.slice(:email)
  end
end
