module Registration
  class CreateApplication
    def initialize(repository:, step:)
      @step = step
      @repository = repository
      @state_store = @step.wizard.valid_answers_store
      @institution = @state_store.institution
      @funding_calculator = @state_store.funding_calculator
      @user = @state_store.current_user
    end

    def execute
      @application = create_application

      { success: true, application_id: @application.ecf_id }
    end

  private

    def create_application
      @user.applications.create!(
        course_id: @state_store.course.id,
        lead_provider_id: @state_store.lead_provider_id,
        private_childcare_provider:,
        school:,
        ukprn:,
        headteacher_status: @state_store.ehco_headteacher_status,
        eligible_for_funding: @funding_calculator.funded?,
        funding_eligiblity_status_code: @funding_calculator.funding_eligiblity_status_code,
        funding_choice:,
        teacher_catchment: @state_store.teacher_catchment,
        works_in_school: @state_store.works_in_school?,
        employer_name: @state_store.relevant_employer_name,
        employment_role: @state_store.relevant_employment_role,
        employment_type: @state_store.relevant_employment_type,
        targeted_delivery_funding_eligibility: false,
        primary_establishment: !!school&.primary_education_phase?,
        number_of_pupils: !!school && school.number_of_pupils, # FIXME: Buggy, assigns false, which casts to 0
        tsf_primary_eligibility: false,
        tsf_primary_plus_eligibility: false,
        works_in_childcare: @state_store.works_in_childcare?,
        kind_of_nursery: @state_store.kind_of_nursery,
        work_setting: @state_store.work_setting,
        lead_mentor: lead_mentor?,
        itt_provider:,
        referred_by_return_to_teaching_adviser: @state_store.referred_by_return_to_teaching_adviser,
        raw_application_data:,
        senco_in_role: @state_store.senco_in_role,
        senco_start_date: @state_store.senco_start_date,
        on_submission_trn: @state_store.trn, # FIXME: REVISIT
        teacher_catchment_country: catchment_area.teacher_catchment_country,
        teacher_catchment_iso_country_code:
          catchment_area.teacher_catchment_iso_country_code,
        cohort: Cohort.current,
        lead_provider_approval_status: Application.lead_provider_approval_statuses[:pending],
        review_status: @funding_calculator.subject_to_review? && "needs_review",
      )
    end

    def school
      @institution if @institution.is_a?(School)
    end

    def private_childcare_provider
      @institution if @institution.is_a?(PrivateChildcareProvider)
    end

    def itt_provider
      return if @state_store.itt_provider.blank?

      IttProvider.find_by(legal_name: @state_store.itt_provider)
    end

    def catchment_area
      @catchment_area ||=
        CatchmentArea.new(teacher_catchment: @state_store.teacher_catchment,
                          country_name: @state_store.teacher_catchment_country)
    end

    def lead_mentor?
      @state_store.employment_type ==
        Application.employment_types[:lead_mentor_for_accredited_itt_provider]
    end

    def ukprn
      return nil unless @state_store.inside_catchment?

      case @institution
      when LocalAuthority, School
        @institution.ukprn
      end
    end

    def funding_choice
      return if @funding_calculator.funded?

      @state_store.course.ehco? ? @state_store.ehco_funding_choice : @state_store.funding
    end

    def raw_application_data
      @state_store.read.except("current_user", "current_user_id")
    end
  end
end
