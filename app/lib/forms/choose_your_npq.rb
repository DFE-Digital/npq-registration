module Forms
  class ChooseYourNpq < Base
    include Helpers::Institution

    attr_accessor :course_id

    validates :course_id, presence: true
    validate :validate_course_exists

    def self.permitted_params
      %i[
        course_id
      ]
    end

    def after_save
      return if lead_provider_valid?

      wizard.store["lead_provider_id"] = nil
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
          :about_ehco
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
        :about_ehco
      elsif eligible_for_funding?
        :possible_funding
      elsif wizard.query_store.works_in_other?
        :choose_your_provider
      else
        :ineligible_for_funding
      end
    end

    def previous_step
      if query_store.inside_catchment? && query_store.works_in_school?
        :choose_school
      elsif query_store.inside_catchment? && query_store.works_in_childcare?
        if query_store.works_in_nursery? && query_store.kind_of_nursery_public?
          :choose_childcare_provider
        elsif query_store.has_ofsted_urn?
          :choose_private_childcare_provider
        else
          :have_ofsted_urn
        end
      elsif wizard.tra_get_an_identity_omniauth_integration_active?
        :get_an_identity
      else
        :qualified_teacher_check
      end
    end

    def options
      courses.each_with_index.map do |course, index|
        OpenStruct.new(value: course.id,
                       text: course.name,
                       link_errors: index.zero?,
                       hint: course.description)
      end
    end

    def course
      courses.find_by(id: course_id)
    end

  private

    def lead_provider_valid?
      valid_providers.include?(wizard.query_store.lead_provider)
    end

    def valid_providers
      LeadProvider.for(course:)
    end

    def courses
      Course.where(display: true).order(:position)
    end

    def previous_course
      Course.find_by(id: wizard.store["course_id"])
    end

    def previously_eligible_for_funding?
      Services::FundingEligibility.new(
        course: previous_course,
        institution:,
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
        trn: wizard.query_store.trn,
      ).funded?
    end

    def funding_eligibility_calculator
      @funding_eligibility_calculator ||= Services::FundingEligibility.new(
        course:,
        institution:,
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
        trn: wizard.query_store.trn,
      )
    end

    def eligible_for_funding?
      funding_eligibility_calculator.funded?
    end

    delegate :ineligible_institution_type?, to: :funding_eligibility_calculator
    delegate :new_headteacher?, :inside_catchment?, to: :query_store

    def validate_course_exists
      if course.blank?
        errors.add(:course_id, :invalid)
      end
    end
  end
end
