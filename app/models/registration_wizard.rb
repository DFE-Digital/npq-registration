require "active_support/time"

class RegistrationWizard
  include ActiveModel::Model
  include Forms::Helpers::Institution
  include ActionView::Helpers::TranslationHelper

  class InvalidStep < StandardError; end

  attr_reader :current_step, :params, :store, :request

  def initialize(current_step:, store:, request:, params: {})
    current_step = :closed if Services::Feature.registration_closed?
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
    array = []

    array << OpenStruct.new(key: "Where do you work?",
                            value: query_store.teacher_catchment_humanized,
                            change_step: :teacher_catchment)

    work_setting = store["work_setting"]

    array << OpenStruct.new(key: "What setting do you work in?",
                            value: I18n.t("registration_wizard.work_setting.#{work_setting}"),
                            change_step: :work_setting)

    array << OpenStruct.new(key: "Full name",
                            value: store["full_name"],
                            change_step: :qualified_teacher_check)

    array << OpenStruct.new(key: "TRN",
                            value: store["trn"],
                            change_step: :qualified_teacher_check)

    array << OpenStruct.new(key: "Date of birth",
                            value: query_store.formatted_date_of_birth,
                            change_step: :qualified_teacher_check)

    if form_for_step(:qualified_teacher_check).national_insurance_number.present?
      array << OpenStruct.new(key: "National Insurance number",
                              value: store["national_insurance_number"],
                              change_step: :qualified_teacher_check)
    end

    array << OpenStruct.new(key: "Email",
                            value: store["confirmed_email"],
                            change_step: :contact_details)

    if inside_catchment? && query_store.works_in_childcare?
      array << OpenStruct.new(key: "Do you work in a nursery?",
                              value: I18n.t(store["works_in_nursery"], scope: "helpers.label.registration_wizard.works_in_nursery_options"),
                              change_step: :work_in_nursery)

      if query_store.works_in_nursery?
        kind_of_nursery = store["kind_of_nursery"]

        array << OpenStruct.new(key: "Type of nursery",
                                value: I18n.t("registration_wizard.kind_of_nursery.#{kind_of_nursery}"),
                                change_step: :kind_of_nursery)
      end

      if query_store.kind_of_nursery_private? || !query_store.works_in_nursery?
        array << if query_store.has_ofsted_urn?
                   OpenStruct.new(key: "Ofsted registration details",
                                  value: institution_from_store.registration_details,
                                  change_step: :have_ofsted_urn)
                 else
                   OpenStruct.new(key: "Do you have a URN?",
                                  value: store["has_ofsted_urn"].capitalize,
                                  change_step: :have_ofsted_urn)
                 end
      end
    end

    if inside_catchment?
      if query_store.works_in_school?
        array << OpenStruct.new(key: "Workplace",
                                value: institution_from_store.name,
                                change_step: :find_school)
      elsif query_store.works_in_childcare? && query_store.works_in_nursery? && query_store.kind_of_nursery_public?
        array << OpenStruct.new(key: "Nursery",
                                value: institution_from_store.name,
                                change_step: :find_childcare_provider)
      end
    end

    if employer_data_gathered?
      array << OpenStruct.new(key: "Employment type",
                              value: I18n.t(store["employment_type"], scope: "helpers.label.registration_wizard.employment_type_options"),
                              change_step: :your_employment)

      array << OpenStruct.new(key: "Role",
                              value: store["employment_role"],
                              change_step: :your_role)

      array << OpenStruct.new(key: "Employer",
                              value: store["employer_name"],
                              change_step: :your_employer)
    end

    array << OpenStruct.new(key: "Course",
                            value: query_store.course.name,
                            change_step: :choose_your_npq)

    unless eligible_for_funding?
      if course.aso?
        array << OpenStruct.new(key: "How is the Additional Support Offer being paid for?",
                                value: I18n.t(store["aso_funding_choice"], scope: "registration_wizard.funding_your_aso.funding_options"),
                                change_step: :funding_your_aso)
      elsif course.ehco?
        array << OpenStruct.new(key: "How is your EHCO being paid for?",
                                value: I18n.t(store["aso_funding_choice"], scope: "registration_wizard.funding_your_aso.funding_options"),
                                change_step: :funding_your_aso)
      elsif query_store.works_in_school? || query_store.works_in_childcare?
        array << OpenStruct.new(key: "How is your NPQ being paid for?",
                                value: I18n.t(store["funding"], scope: "registration_wizard.funding_your_npq.funding_options"),
                                change_step: :funding_your_npq)
      end
    end

    if course.ehco?
      array << OpenStruct.new(key: "Have you completed an NPQH?",
                              value: I18n.t(store["npqh_status"], scope: "activemodel.attributes.forms/npqh_status.status_options"),
                              change_step: :npqh_status)

      array << OpenStruct.new(key: "Are you a headteacher?",
                              value: store["aso_headteacher"].capitalize,
                              change_step: :aso_headteacher)

      if store["aso_headteacher"] == "yes"
        array << OpenStruct.new(key: "Are you in your first 5 years of a headship?",
                                value: store["aso_new_headteacher"].capitalize,
                                change_step: :aso_new_headteacher)
      end
    end

    array << OpenStruct.new(key: "Lead provider",
                            value: query_store.lead_provider.name,
                            change_step: :choose_your_provider)

    array
  end

  def form_for_step(step)
    form_class = "Forms::#{step.to_s.camelcase}".constantize
    hash = store.slice(*form_class.permitted_params.map(&:to_s))
    hash.merge!(wizard: self)
    form_class.new(hash)
  end

  def query_store
    @query_store ||= Services::QueryStore.new(store:)
  end

private

  def institution_from_store
    institution(source: store["institution_identifier"])
  end

  def funding_eligibility_calculator
    Services::FundingEligibility.new(
      course:,
      institution: institution_from_store,
      inside_catchment: inside_catchment?,
      new_headteacher: new_headteacher?,
      trn: store["trn"],
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

  delegate :new_headteacher?, :inside_catchment?, :works_in_other?, to: :query_store

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
      closed
      teacher_catchment
      work_setting
      provider_check
      about_npq
      teacher_reference_number
      change_dqt
      dont_have_teacher_reference_number
      contact_details
      confirm_email
      resend_code
      qualified_teacher_check
      not_sure_updated_name
      dqt_mismatch
      about_ehco
      npqh_status
      aso_unavailable
      aso_headteacher
      aso_new_headteacher
      aso_funding_not_available
      aso_previously_funded
      aso_possible_funding
      funding_your_aso
      choose_your_npq
      choose_your_provider
      find_school
      choose_school
      find_childcare_provider
      choose_childcare_provider
      work_in_childcare
      work_in_nursery
      kind_of_nursery
      have_ofsted_urn
      choose_private_childcare_provider
      your_employment
      your_role
      your_employer
      school_not_in_england
      possible_funding
      ineligible_for_funding
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
