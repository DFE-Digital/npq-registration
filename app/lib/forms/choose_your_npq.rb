module Forms
  class ChooseYourNpq < Base
    include Helpers::Institution

    QUESTION_NAME = :course_identifier

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true
    validate :validate_course_exists

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        Forms::QuestionTypes::RadioButtonGroup.new(
          name: :course_identifier,
          options:,
          style_options: { legend: { size: "m", tag: "h1" } },
        ),
      ]
    end

    def options
      divider_index = courses.length - 1 # Place the "Or" divider before the last course
      courses.reject { |course| course.identifier == "npq-leading-primary-mathematics" && !Flipper.enabled?(:maths_npq) }
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
      wizard.store["targeted_delivery_funding_eligibility"] = funding_eligibility_calculator.targeted_funding[:targeted_delivery_funding]
      wizard.store["tsf_primary_plus_eligibility"] = funding_eligibility_calculator.targeted_funding[:tsf_primary_plus_eligibility]
      wizard.store["tsf_primary_eligibility"] = funding_eligibility_calculator.targeted_funding[:tsf_primary_eligibility]
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
          if wizard.query_store.works_in_other?
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
      elsif eligible_for_funding?
        :possible_funding
      elsif wizard.query_store.works_in_other?
        if lead_mentor?
          :ineligible_for_funding
        elsif wizard.query_store.employment_type_other? || wizard.query_store.valid_employent_type_for_england?
          :possible_funding
        else
          :choose_your_provider
        end
      else
        :ineligible_for_funding
      end
    end

    def previous_step
      if query_store.inside_catchment? && query_store.works_in_school?
        :choose_school
      elsif query_store.inside_catchment? && query_store.works_in_childcare?
        if query_store.kind_of_nursery_public?
          :choose_childcare_provider
        elsif query_store.has_ofsted_urn?
          :choose_private_childcare_provider
        else
          :have_ofsted_urn
        end
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
      Services::FundingEligibility.new(
        course: previous_course,
        institution:,
        approved_itt_provider: approved_itt_provider?,
        lead_mentor: lead_mentor?,
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
        trn: wizard.query_store.trn,
        get_an_identity_id: wizard.query_store.get_an_identity_id,
      ).funded?
    end

    def funding_eligibility_calculator
      @funding_eligibility_calculator ||= Services::FundingEligibility.new(
        course:,
        institution:,
        approved_itt_provider: approved_itt_provider?,
        lead_mentor: lead_mentor?,
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
        trn: wizard.query_store.trn,
        get_an_identity_id: wizard.query_store.get_an_identity_id,
      )
    end

    def eligible_for_funding?
      funding_eligibility_calculator.funded?
    end

    delegate :ineligible_institution_type?, to: :funding_eligibility_calculator
    delegate :new_headteacher?, :inside_catchment?, :approved_itt_provider?, to: :query_store

    def validate_course_exists
      if course.blank?
        errors.add(:course_identifier, :invalid)
      end
    end
  end
end
