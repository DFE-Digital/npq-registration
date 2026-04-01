module Registration
  class StateStore
    include DfE::Wizard::StateStore

    attr_reader :current_user

    def initialize(*args, current_user:, **kwargs, &block)
      @current_user = current_user

      super(*args, **kwargs, &block)
    end

    def [](key)
      data = read
      data.key?(key) ? data[key] : data[key.to_sym]
    end

    def service_closed?
      Feature.registration_closed?(current_user)
    end

    def user_missing_trn?
      return false if current_user&.teacher_auth_provider?

      # Full name is to avoid changing valid_path once we update the users trn
      # via the DQT check
      current_user&.trn.blank? || full_name.present?
    end

    def not_starting_in_current_cohort?
      course_start_date == "no"
    end

    def not_chosen_provider?
      chosen_provider == "no"
    end

    def inside_catchment?
      teacher_catchment == "england"
    end

    def works_in_school?
      Questionnaires::WorkSetting::SCHOOL_SETTINGS.include?(work_setting)
    end

    def inside_catchment_and_works_in_school?
      inside_catchment? && works_in_school?
    end

    def works_in_childcare?
      Questionnaires::WorkSetting::CHILDCARE_SETTINGS.include?(work_setting)
    end

    def inside_catchment_and_works_in_childcare?
      inside_catchment? && works_in_childcare?
    end

    def works_in_another_setting?
      Questionnaires::WorkSetting::ANOTHER_SETTING_SETTINGS.include?(work_setting)
    end

    def inside_catchment_and_works_in_another_setting?
      inside_catchment? && works_in_another_setting?
    end

    def works_in_other?
      Questionnaires::WorkSetting::OTHER_SETTINGS.include?(work_setting)
    end

    def inside_catchment_and_works_in_other?
      inside_catchment? && works_in_other?
    end

    def employment_type_local_authority_virtual_school?
      employment_type == Application.employment_types[:local_authority_virtual_school]
    end

    def local_authority_supply_teacher?
      employment_type == Application.employment_types[:local_authority_supply_teacher]
    end

    def lead_mentor_for_accredited_itt_provider?
      employment_type == Application.employment_types[:lead_mentor_for_accredited_itt_provider]
    end

    def employment_type_hospital_school?
      employment_type == Application.employment_types[:hospital_school]
    end

    def young_offender_institution?
      employment_type == Application.employment_types[:young_offender_institution]
    end

    def employment_type_other?
      employment_type == Application.employment_types[:other]
    end

    def kind_of_nursery_public?
      Questionnaires::KindOfNursery::KIND_OF_NURSERY_PUBLIC_OPTIONS.include?(kind_of_nursery)
    end

    def kind_of_nursery_private?
      Questionnaires::KindOfNursery::KIND_OF_NURSERY_PRIVATE_OPTIONS.include?(kind_of_nursery)
    end

    def institution_not_in_england?
      !institution&.in_england?
    end

    def valid_employent_type_for_england?
      inside_catchment? && !employment_type_other? && !lead_mentor_for_accredited_itt_provider?
    end

    def has_ofsted_urn?
      has_ofsted_urn == "yes"
    end

    def headship_course_requirement?
      npqh_status != "none"
    end

    def ehco_headteacher?
      ehco_headteacher != "no"
    end

    def ineligible_for_maths_mastery?
      maths_eligibility_teaching_for_mastery != "yes"
    end

    def eligible_for_funding?
      @eligible_for_funding ||= funding_calculator.funded?
    end

    def funded_subject_to_review?
      @funded_subject_to_review ||= funding_calculator.subject_to_review?
    end

    def previously_funded?
      @previously_funded ||= funding_calculator.previously_funded?
    end

    def maths_cannot_show_understanding_of_approach?
      maths_understanding_of_approach == "cannot_show"
    end

    def senco_in_role?
      senco_in_role == "yes"
    end

    def ehco_course?
      course&.ehco?
    end

    def leading_primary_maths_course?
      course&.npqlpm?
    end

    def senco_course?
      course&.npqs?
    end

    def user_does_not_know_trn?
      trn_knowledge == "no-dont-have"
    end

    def trn_is_verified?
      current_user&.trn_verified?
    end

    def childminder?
      kind_of_nursery == "childminder"
    end

    def referred_by_return_to_teaching_adviser?
      referred_by_return_to_teaching_adviser == "yes"
    end

    def new_headteacher?
      ehco_headteacher == "yes" && ehco_new_headteacher == "yes"
    end

    def approved_itt_provider?
      @approved_itt_provider ||=
        ::IttProvider.currently_approved.exists?(legal_name: itt_provider)
    end

    def tsf_primary_eligibility? = false
    def tsf_primary_plus_eligibility? = false
    def targeted_delivery_funding_eligibility? = false

    def ehco_headteacher_status
      return nil unless course.ehco?
      return :no if ehco_headteacher == "no"

      ehco_new_headteacher == "yes" ? :yes_in_first_five_years : :yes_over_five_years
    end

    def employment_type_matters?
      inside_catchment_and_works_in_another_setting? || lead_mentor_for_accredited_itt_provider?
    end

    def employment_role_matters?
      return false unless employment_type_matters?

      [
        lead_mentor_for_accredited_itt_provider?,
        employment_type_hospital_school?,
        young_offender_institution?,
        employment_type_other?,
      ].none?
    end

    def employer_name_matters?
      return true if referred_by_return_to_teaching_adviser?
      return false unless employment_type_matters?

      !(lead_mentor_for_accredited_itt_provider? || employment_type_other?)
    end

    def relevant_employment_type
      employment_type.presence if employment_type_matters?
    end

    def relevant_employment_role
      employment_role.presence if employment_role_matters?
    end

    def relevant_employer_name
      if referred_by_return_to_teaching_adviser?
        "Return to teaching adviser referral"
      elsif employer_name_matters?
        employer_name.presence
      end
    end

    def funding_calculator
      @funding_calculator ||= FundingEligibility.new(
        institution:,
        course:,
        inside_catchment: inside_catchment?,
        trn: current_user&.trn,
        get_an_identity_id: current_user&.get_an_identity_id,
        approved_itt_provider: approved_itt_provider?,
        new_headteacher: new_headteacher?,
        employment_type:,
        childminder: childminder?,
        referred_by_return_to_teaching_adviser: referred_by_return_to_teaching_adviser?,
        work_setting:,
      )
    end

    def institution
      @institution ||=
        if works_in_school? && !works_in_childcare?
          Registration::Institution.fetch(identifier: institution_identifier,
                                          works_in_school: true,
                                          works_in_childcare: false)
        elsif works_in_childcare? && !works_in_school?
          if kind_of_nursery_public?
            Registration::Institution.fetch(identifier: childcare_identifier,
                                            works_in_school: false,
                                            works_in_childcare: true)
          elsif has_ofsted_urn?
            Registration::Institution.fetch(identifier: private_childcare_identifier,
                                            works_in_school: false,
                                            works_in_childcare: true)
          end
        end
    end

    def course
      @course ||= Course.find_by(identifier: course_identifier)
    end

    def lead_provider
      @lead_provider ||= LeadProvider.find_by(id: lead_provider_id)
    end
  end
end
