require "active_support/time"

class RegistrationWizard
  include ActiveModel::Model
  include Helpers::Institution
  include ActionView::Helpers::TranslationHelper

  class InvalidStep < StandardError; end
  class RemovedStep < StandardError; end

  Answer = Struct.new(:key, :value, :change_step)

  VALID_REGISTRATION_STEPS = %i[
    start
    closed
    teacher_catchment
    referred_by_return_to_teaching_adviser
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
    choose_school
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

  REMOVED_REGISTRATION_STEPS = %i[
    about_npq
    choosen_start_date
    confirmation
    find_school
    find_childcare_provider
  ].freeze

  attr_reader :current_step, :params, :store, :request, :current_user

  delegate :before_render,
           :after_render,
           :skip_step?,
           to: :form

  delegate :session, to: :request

  class << self
    def validate_step!(step)
      return step.to_sym if VALID_REGISTRATION_STEPS.include?(step.to_sym)

      raise RemovedStep, "This step has been removed: #{step}" if REMOVED_REGISTRATION_STEPS.include?(step.to_sym)

      raise InvalidStep, "Could not find step: #{step}"
    end

    def fetch_step(step)
      validate_step!(step)

      "Questionnaires::#{step.to_s.camelcase}".constantize
    end

    def permitted_params_for_step(step)
      fetch_step(step).permitted_params
    end
  end

  def initialize(current_step:, store:, request:, current_user:, params: {})
    set_current_step(current_step)

    @current_user = current_user
    @params = params
    @store = store
    @request = request

    load_current_user_into_store
  end

  def form
    @form ||= begin
      hash = store.slice(*form_class.permitted_params.map(&:to_s))
      form_class.new hash.merge(params, wizard: self)
    end
  end

  def save!
    form.attributes.each { |k, v| store[k.to_s] = v }
    form.after_save
  end

  def next_step_path
    form.next_step.to_s.dasherize
  end

  def previous_step_path
    form.previous_step.to_s.dasherize
  end

  def answers
    array = []

    if trn_set_via_fallback_verification_question?
      array << Answer.new("Full name", store["full_name"], :qualified_teacher_check)
      array << Answer.new("Teacher reference number (TRN)", trn, :qualified_teacher_check)
      array << Answer.new("Date of birth", formatted_date_of_birth, :qualified_teacher_check)

      if form_for_step(:qualified_teacher_check).national_insurance_number.present?
        array << Answer.new("National Insurance number", store["national_insurance_number"], :qualified_teacher_check)
      end
    end

    array << Answer.new("Course start", store["course_start"], :course_start_date)
    array << Answer.new("Workplace in England", teacher_catchment_humanized, :teacher_catchment)

    if store["referred_by_return_to_teaching_adviser"]
      array << Answer.new("Referred by return to teaching adviser", t("referred_by_return_to_teaching_adviser"), :referred_by_return_to_teaching_adviser)
    end

    if store["work_setting"]
      array << Answer.new("Work setting", t("work_setting"), :work_setting)
    end

    if inside_catchment? && works_in_childcare?
      array << Answer.new("Early years setting", t("kind_of_nursery"), :kind_of_nursery)

      if kind_of_nursery_private?
        value = if has_ofsted_urn?
                  institution_from_store.registration_details
                else
                  store["has_ofsted_urn"] == "no" ? "Not applicable" : t("has_ofsted_urn")
                end

        array << Answer.new("Ofsted unique reference number (URN)", value, :have_ofsted_urn)
      end
    end

    if inside_catchment?
      if works_in_school?
        array << Answer.new("Workplace", institution_from_store.try(:name_with_address), :choose_school)
      elsif works_in_childcare? && kind_of_nursery_public?
        array << Answer.new("Workplace", institution_from_store.try(:name_with_address), :choose_childcare_provider)
      end
    end

    if employment_type_matters?
      array << Answer.new("Employment type", t("employment_type"), :your_employment)
      array << Answer.new("ITT provider", itt_provider, :itt_provider) if lead_mentor_for_accredited_itt_provider?
      array << Answer.new("Role", store["employment_role"], :your_role) if employment_role_matters?
      array << Answer.new("Employer", store["employer_name"], :your_employer) if employer_name_matters?
    end

    array << Answer.new("Course", I18n.t(course.identifier, scope: "course.name"), :choose_your_npq)

    if course.ehco?
      array << Answer.new("Headship NPQ stage", t("npqh_status"), :npqh_status)
      array << Answer.new("Headteacher", t("ehco_headteacher"), :ehco_headteacher)

      if store["ehco_headteacher"] == "yes"
        array << Answer.new("First 5 years of headship", t("ehco_new_headteacher"), :ehco_new_headteacher)
      end
    end

    if course.npqs?
      value = store["senco_in_role_status"] ? "Yes – since #{store["senco_start_date"].to_fs(:govuk_approx)}" : t("senco_in_role")
      array << Answer.new("Special educational needs co-ordinator (SENCO)", value, :senco_in_role)
    end

    if course.npqlpm?
      value = if store["maths_eligibility_teaching_for_mastery"] == "yes"
                store["maths_eligibility_teaching_for_mastery"].capitalize
              else
                t("maths_understanding_of_approach")
              end

      array << Answer.new("Completed one year of the primary maths Teaching for Mastery programme", value, :maths_eligibility_teaching_for_mastery)
    end

    unless funding_eligibility_calculator.funded?
      if course.ehco? && store["ehco_funding_choice"]
        array << Answer.new("Course funding", t("ehco_funding_choice"), :funding_your_ehco)
      elsif store["funding"] && (works_in_school? || works_in_childcare? || works_in_another_setting? || works_in_other?)
        array << Answer.new("Course funding", t("funding"), :funding_your_npq)
      elsif !course.npqltd? && lead_mentor_for_accredited_itt_provider?
        array << Answer.new("Course funding", t("funding"), :funding_your_npq)
      end
    end

    array << Answer.new("Provider", lead_provider&.name, :choose_your_provider)

    array
  end

  def query_store
    @query_store ||= RegistrationQueryStore.new(store:)
  end

private

  delegate :approved_itt_provider?,
           :course,
           :employment_type_matters?,
           :employment_role_matters?,
           :employer_name_matters?,
           :employment_type_hospital_school?,
           :employment_type_other?,
           :formatted_date_of_birth,
           :get_an_identity_id,
           :has_ofsted_urn?,
           :inside_catchment?,
           :itt_provider,
           :kind_of_nursery_private?,
           :kind_of_nursery_public?,
           :lead_mentor_for_accredited_itt_provider?,
           :lead_provider,
           :new_headteacher?,
           :teacher_catchment_humanized,
           :trn,
           :trn_set_via_fallback_verification_question?,
           :works_in_another_setting?,
           :works_in_childcare?,
           :works_in_other?,
           :works_in_school?,
           :young_offender_institution?,
           to: :query_store

  def form_for_step(step)
    form_class = self.class.fetch_step(step)
    hash = store.slice(*form_class.permitted_params.map(&:to_s))
    form_class.new hash.merge(wizard: self)
  end

  def load_current_user_into_store
    store["current_user_id"] = current_user&.id
  end

  def institution_from_store
    @institution_from_store ||= institution(source: store["institution_identifier"])
  end

  def funding_eligibility_calculator
    FundingEligibility.new_from_query_store(
      course:,
      institution: institution_from_store,
      approved_itt_provider: approved_itt_provider?,
      inside_catchment: inside_catchment?,
      new_headteacher: new_headteacher?,
      trn:,
      get_an_identity_id:,
      query_store:,
    )
  end

  def form_class
    @form_class ||= self.class.fetch_step(current_step)
  end

  def set_current_step(step)
    @current_step = self.class.validate_step!(step)
  end

  def t(key)
    I18n.t(store[key], scope: "helpers.label.registration_wizard.#{key}_options")
  end
end
