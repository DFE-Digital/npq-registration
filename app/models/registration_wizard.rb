class RegistrationWizard
  include ActiveModel::Model

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
    school = School.find_by(urn: store["school_urn"])

    array = []
    array << OpenStruct.new(key: "Full name",
                            value: store["full_name"],
                            change_step: :qualified_teacher_check)
    array << OpenStruct.new(key: "TRN",
                            value: store["trn"],
                            change_step: :qualified_teacher_check)
    array << OpenStruct.new(key: "Date of birth",
                            value: dob.to_s(:long),
                            change_step: :qualified_teacher_check)

    if form_for_step(:qualified_teacher_check).national_insurance_number.present?
      array << OpenStruct.new(key: "National Insurance number",
                              value: store["national_insurance_number"],
                              change_step: :qualified_teacher_check)
    end

    array << OpenStruct.new(key: "Email",
                            value: store["confirmed_email"],
                            change_step: :contact_details)
    array << OpenStruct.new(key: "NPQ",
                            value: form_for_step(:choose_your_npq).course.name,
                            change_step: :choose_your_npq)

    if form_for_step(:choose_your_npq).studying_for_headship?
      array << OpenStruct.new(key: "Have you been a headteacher for two years or more?",
                              value: store["headerteacher_over_two_years"].humanize,
                              change_step: :headteacher_duration)
    end

    array << OpenStruct.new(key: "Lead provider",
                            value: form_for_step(:choose_your_provider).lead_provider.name,
                            change_step: :choose_your_provider)
    array << OpenStruct.new(key: "School",
                            value: school.name,
                            change_step: :find_school)
  end

private

  def form_for_step(step)
    form_class = "Forms::#{step.to_s.camelcase}".constantize
    hash = store.slice(*form_class.permitted_params.map(&:to_s))
    hash.merge!(wizard: self)
    form_class.new(hash)
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
      share_provider
      teacher_reference_number
      name_changes
      updated_name
      not_sure_updated_name
      not_updated_name
      change_dqt
      dont_know_teacher_reference_number
      dont_have_teacher_reference_number
      contact_details
      confirm_email
      resend_code
      qualified_teacher_check
      dqt_mismatch
      choose_your_npq
      headteacher_duration
      choose_your_provider
      find_school
      choose_school
      school_not_in_england
      check_answers
      confirmation
    ]
  end

  def submission_params
    params.slice(:email)
  end
end
