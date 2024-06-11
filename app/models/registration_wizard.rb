require "active_support/time"

class RegistrationWizard
  include ActiveModel::Model
  include Helpers::Institution
  include ActionView::Helpers::TranslationHelper

  class InvalidStep < StandardError; end

  VALID_REGISTRATION_STEPS = %i[
    start
    closed
    teacher_catchment
    work_setting
    provider_check
    change_your_course_or_provider
    choose_an_npq_and_provider
    get_an_identity_callback
    teacher_reference_number
    dont_have_teacher_reference_number
    qualified_teacher_check
    dqt_mismatch
    npqh_status
    ehco_unavailable
    ehco_headteacher
    ehco_new_headteacher
    ehco_funding_not_available
    ehco_previously_funded
    ehco_possible_funding
    funding_your_ehco
    itt_provider
    choose_your_npq
    maths_eligibility_teaching_for_mastery
    maths_understanding_of_approach
    maths_cannot_register
    senco_in_role
    funding_eligibility_senco
    senco_start_date
    funding_eligibility_maths
    choose_your_provider
    find_school
    choose_school
    find_childcare_provider
    choose_childcare_provider
    kind_of_nursery
    have_ofsted_urn
    choose_private_childcare_provider
    your_employment
    your_role
    your_employer
    school_not_in_england
    childcare_provider_not_in_england
    possible_funding
    ineligible_for_funding
    funding_your_npq
    share_provider
    check_answers
    course_start_date
    cannot_register_yet
  ].freeze

  attr_reader :current_step, :params, :store, :request, :current_user

  def initialize(current_step:, store:, request:, current_user:, params: {})
    set_current_step(current_step)

    @current_user = current_user
    @params = params
    @store = store
    @request = request

    load_current_user_into_store
  end

  def self.permitted_params_for_step(step)
    "Questionnaires::#{step.to_s.camelcase}".constantize.permitted_params
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

  def skip_step?
    form.skip_step?
  end

  def answers
    array = []

    if query_store.trn_set_via_fallback_verification_question?
      array << OpenStruct.new(key: "Full name",
                              value: store["full_name"],
                              change_step: :qualified_teacher_check)

      array << OpenStruct.new(key: "Teacher reference number (TRN)",
                              value: query_store.trn,
                              change_step: :qualified_teacher_check)

      array << OpenStruct.new(key: "Date of birth",
                              value: query_store.formatted_date_of_birth,
                              change_step: :qualified_teacher_check)

      if form_for_step(:qualified_teacher_check).national_insurance_number.present?
        array << OpenStruct.new(key: "National Insurance number",
                                value: store["national_insurance_number"],
                                change_step: :qualified_teacher_check)
      end
    end

    array << OpenStruct.new(key: "Course start",
                            value: store["course_start"],
                            change_step: :course_start_date)

    array << OpenStruct.new(key: "Workplace in England",
                            value: query_store.teacher_catchment_humanized,
                            change_step: :teacher_catchment)

    array << OpenStruct.new(key: "Work setting",
                            value: I18n.t(store["work_setting"], scope: "helpers.label.registration_wizard.work_setting_options"),
                            change_step: :work_setting)

    if inside_catchment? && query_store.works_in_childcare?
      array << OpenStruct.new(key: "Early years setting",
                              value: I18n.t(store["kind_of_nursery"], scope: "helpers.label.registration_wizard.kind_of_nursery_options"),
                              change_step: :kind_of_nursery)
      if query_store.kind_of_nursery_private?
        array << if query_store.has_ofsted_urn?
                   OpenStruct.new(key: "Ofsted unique reference number (URN)",
                                  value: institution_from_store.registration_details,
                                  change_step: :have_ofsted_urn)
                 else
                   OpenStruct.new(key: "Ofsted unique reference number (URN)",
                                  value: store["has_ofsted_urn"] == "no" ? "Not applicable" : I18n.t(store["has_ofsted_urn"], scope: "helpers.label.registration_wizard.has_ofsted_urn_options"),
                                  change_step: :have_ofsted_urn)
                 end
      end
    end

    if inside_catchment?
      if query_store.works_in_school?
        array << OpenStruct.new(key: "Workplace",
                                value: institution_from_store.name_with_address,
                                change_step: :find_school)
      elsif query_store.works_in_childcare? && query_store.kind_of_nursery_public?
        array << OpenStruct.new(key: "Workplace",
                                value: institution_from_store.name_with_address,
                                change_step: :find_childcare_provider)
      end
    end

    if employer_data_gathered? || query_store.lead_mentor_for_accredited_itt_provider?
      array << OpenStruct.new(key: "Employment type",
                              value: I18n.t(store["employment_type"], scope: "helpers.label.registration_wizard.employment_type_options"),
                              change_step: :your_employment)

      if query_store.lead_mentor_for_accredited_itt_provider?
        array << OpenStruct.new(key: "ITT provider",
                                value: query_store.itt_provider,
                                change_step: :itt_provider)
      end

      unless query_store.lead_mentor_for_accredited_itt_provider?
        array << OpenStruct.new(key: "Role",
                                value: store["employment_role"],
                                change_step: :your_role)

        array << OpenStruct.new(key: "Employer",
                                value: store["employer_name"],
                                change_step: :your_employer)
      end
    end

    array << OpenStruct.new(key: "Course",
                            value: I18n.t(query_store.course.identifier, scope: "course.name"),
                            change_step: :choose_your_npq)

    if course.ehco?
      array << OpenStruct.new(key: "Headship NPQ stage",
                              value: I18n.t(store["npqh_status"], scope: "helpers.label.registration_wizard.npqh_status_options"),
                              change_step: :npqh_status)

      array << OpenStruct.new(key: "Headteacher",
                              value: I18n.t(store["ehco_headteacher"], scope: "helpers.label.registration_wizard.ehco_headteacher_options"),
                              change_step: :ehco_headteacher)

      if store["ehco_headteacher"] == "yes"
        array << OpenStruct.new(key: "First 5 years of headship",
                                value: I18n.t(store["ehco_new_headteacher"], scope: "helpers.label.registration_wizard.ehco_new_headteacher_options"),
                                change_step: :ehco_new_headteacher)
      end
    end

    if course.npqs?
      array << OpenStruct.new(key: "Special educational needs co-ordinator (SENCO)",
                              value: store["senco_in_role_status"] ? "Yes – since #{store["senco_start_date"].strftime("%B %Y")}" : I18n.t(store["senco_in_role"], scope: "helpers.label.registration_wizard.senco_in_role_options"),
                              change_step: :senco_in_role)
    end

    if query_store.course.identifier == "npq-leading-primary-mathematics"
      if store["maths_eligibility_teaching_for_mastery"] == "yes"
        array << OpenStruct.new(key: "Completed one year of the primary maths Teaching for Mastery programme",
                                value: store["maths_eligibility_teaching_for_mastery"].capitalize,
                                change_step: :maths_eligibility_teaching_for_mastery)

      elsif store["maths_eligibility_teaching_for_mastery"] == "no"
        array << OpenStruct.new(key: "Completed one year of the primary maths Teaching for Mastery programme",
                                value: I18n.t("helpers.label.registration_wizard.maths_understanding_of_approach_options.#{store['maths_understanding_of_approach']}"),
                                change_step: :maths_eligibility_teaching_for_mastery)
      end
    end

    unless eligible_for_funding?
      if course.ehco?
        array << OpenStruct.new(key: "Course funding",
                                value: I18n.t(store["ehco_funding_choice"], scope: "helpers.label.registration_wizard.ehco_funding_choice_options"),
                                change_step: :funding_your_ehco)
      elsif query_store.works_in_school? || query_store.works_in_childcare?
        array << OpenStruct.new(key: "Course funding",
                                value: I18n.t(store["funding"], scope: "helpers.label.registration_wizard.funding_options"),
                                change_step: :funding_your_npq)
      elsif !course.npqltd? && query_store.lead_mentor_for_accredited_itt_provider?
        array << OpenStruct.new(key: "Course funding",
                                value: I18n.t(store["funding"], scope: "helpers.label.registration_wizard.funding_options"),
                                change_step: :funding_your_npq)
      end
    end

    array << OpenStruct.new(key: "Provider",
                            value: query_store.lead_provider&.name,
                            change_step: :choose_your_provider)

    array
  end

  def form_for_step(step)
    form_class = "Questionnaires::#{step.to_s.camelcase}".constantize
    hash = store.slice(*form_class.permitted_params.map(&:to_s))
    hash.merge!(wizard: self)
    form_class.new(hash)
  end

  def query_store
    @query_store ||= RegistrationQueryStore.new(store:)
  end

private

  def lead_mentor_course?
    course.npqltd?
  end

  def load_current_user_into_store
    store["current_user"] = current_user
  end

  def institution_from_store
    institution(source: store["institution_identifier"])
  end

  def funding_eligibility_calculator
    FundingEligibility.new(
      course:,
      institution: institution_from_store,
      approved_itt_provider: approved_itt_provider?,
      inside_catchment: inside_catchment?,
      new_headteacher: new_headteacher?,
      trn: query_store.trn,
      get_an_identity_id: query_store.get_an_identity_id,
      kind_of_nursery: query_store.kind_of_nursery,
    )
  end

  def eligible_for_funding?
    funding_eligibility_calculator.funded?
  end

  def employer_data_gathered?
    return false if eligible_for_funding?

    works_in_other? && inside_catchment?
  end

  delegate :ineligible_institution_type?, to: :funding_eligibility_calculator

  delegate :new_headteacher?, :inside_catchment?, :works_in_other?, :course, :approved_itt_provider?, to: :query_store

  def load_from_store
    store.slice(*form_class.permitted_params.map(&:to_s))
  end

  def form_class
    @form_class ||= "Questionnaires::#{current_step.to_s.camelcase}".constantize
  end

  def set_current_step(step)
    @current_step = steps.find { |s| s == step.to_sym }

    raise InvalidStep, "Could not find step: #{step}" if @current_step.nil?
  end

  def steps
    VALID_REGISTRATION_STEPS
  end

  def submission_params
    params.slice(:email)
  end
end
