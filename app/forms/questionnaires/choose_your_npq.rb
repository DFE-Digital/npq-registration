module Questionnaires
  class ChooseYourNpq < Base
    include Helpers::Institution

    QUESTION_NAME = :course_identifier

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true
    validate :validate_course_exists

    delegate :ineligible_institution_type?, to: :funding_eligibility_calculator

    delegate :new_headteacher?,
             :inside_catchment?,
             :approved_itt_provider?,
             :works_in_another_setting?,
             :works_in_school?,
             :young_offender_institution?,
             :referred_by_return_to_teaching_adviser?,
             :employment_type_local_authority_virtual_school?,
             :has_ofsted_urn?,
             :employment_type_hospital_school?,
             :employment_type_other?,
             :works_in_childcare?,
             :kind_of_nursery_public?,
             to: :query_store

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        QuestionTypes::RadioButtonGroup.new(
          name: :course_identifier,
          options:,
          style_options: { legend: { size: "m", tag: "h2" } },
        ),
      ]
    end

    def options
      divider_index = courses.length - 1 # Place the "Or" divider before the last course
      courses
        .each_with_index.map do |course, index|
          build_option_struct(
            value: course.identifier,
            link_errors: index.zero?,
            divider: divider_index == index,
            label: I18n.t("course.name.#{course.identifier}", default: course.name),
          )
        end
    end

    def after_save
      wizard.store["targeted_delivery_funding_eligibility"] = false
      wizard.store["tsf_primary_plus_eligibility"] = false
      wizard.store["tsf_primary_eligibility"] = false
      wizard.store["funding_eligiblity_status_code"] = funding_eligibility_calculator.funding_eligiblity_status_code
      wizard.store["lead_provider_id"] = store_lead_provider_id
    end

    def next_step
      # If your lead provider remains valid we can progress down the changing answer path
      # as it is fine for us to end up going back to the check_answers page.
      # If it is no longer valid due to the NPQ changing though we will need to be
      # reinserted back into the flow so that later on the user can be asked to
      # choose a new provider.
      if changing_answer? && lead_provider_valid?
        if no_answers_will_change?
          :check_answers
        elsif course.ehco?
          :npqh_status
        elsif previously_eligible_for_funding? && !eligible_for_funding?
          if wizard.query_store.works_in_another_setting?
            :choose_your_provider
          else
            :ineligible_for_funding
          end
        else
          :check_answers
        end
      elsif course.ehco?
        :npqh_status
      elsif course.npqlpm?
        :maths_eligibility_teaching_for_mastery
      elsif course.npqs?
        :senco_in_role
      elsif referred_by_return_to_teaching_adviser?
        :possible_funding
      elsif works_in_another_setting?
        if employment_type_other?
          :ineligible_for_funding
        elsif lead_mentor?
          if course.npqltd? && inside_catchment?
            :possible_funding
          else
            :ineligible_for_funding
          end
        elsif inside_catchment?
          :possible_funding
        else
          :ineligible_for_funding
        end
      elsif eligible_for_funding?
        :possible_funding
      else
        :ineligible_for_funding
      end
    end

    def previous_step
      if inside_catchment? && referred_by_return_to_teaching_adviser?
        :referred_by_return_to_teaching_adviser
      elsif inside_catchment? && works_in_school?
        :choose_school
      elsif inside_catchment? && works_in_childcare?
        if kind_of_nursery_public?
          :choose_childcare_provider
        elsif has_ofsted_urn?
          :choose_private_childcare_provider
        else
          :have_ofsted_urn
        end
      elsif inside_catchment? && works_in_another_setting?
        :your_employment
      else
        :work_setting
      end
    end

    def course
      courses.find_by(identifier: course_identifier)
    end

  private

    def store_lead_provider_id
      return wizard.query_store.lead_provider.id if lead_provider_valid?

      nil
    end

    def lead_provider_valid?
      valid_providers.include?(wizard.query_store.lead_provider)
    end

    def valid_providers
      LeadProvider.for(course:)
    end

    def lead_mentor?
      wizard.query_store.lead_mentor_for_accredited_itt_provider?
    end

    def courses
      Course.where(display: true).order(:position)
    end

    def previous_course
      wizard.query_store.course
    end

    def previously_eligible_for_funding?
      FundingEligibility.new(
        course: previous_course,
        institution:,
        approved_itt_provider: approved_itt_provider?,
        lead_mentor: lead_mentor?,
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
        trn: wizard.query_store.trn,
        get_an_identity_id: wizard.query_store.get_an_identity_id,
        query_store: wizard.query_store,
      ).funded?
    end

    def funding_eligibility_calculator
      @funding_eligibility_calculator ||= FundingEligibility.new(
        course:,
        institution:,
        approved_itt_provider: approved_itt_provider?,
        lead_mentor: lead_mentor?,
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
        trn: wizard.query_store.trn,
        get_an_identity_id: wizard.query_store.get_an_identity_id,
        query_store: wizard.query_store,
      )
    end

    def eligible_for_funding?
      funding_eligibility_calculator.funded?
    end

    def validate_course_exists
      if course.blank?
        errors.add(:course_identifier, :invalid)
      end
    end
  end
end
