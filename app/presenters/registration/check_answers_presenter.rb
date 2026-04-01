module Registration
  class CheckAnswersPresenter
    Answer = Struct.new(:key, :value, :change_step)

    delegate_missing_to :@store

    attr_reader :store

    def initialize(store)
      @store = store
    end

    def answers
      array = []

      if full_name.present?
        array << Answer.new("Full name", store["full_name"], :qualified_teacher_check)
        array << Answer.new("Teacher reference number (TRN)", trn, :qualified_teacher_check)
        array << Answer.new("Date of birth", date_of_birth&.to_fs(:govuk), :qualified_teacher_check)

        if national_insurance_number.present?
          array << Answer.new("National Insurance number", store["national_insurance_number"], :qualified_teacher_check)
        end
      end

      array << Answer.new("Course start", course_start, :course_start_date)
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

  private

    def institution_from_store = store.institution
    def funding_eligibility_calculator = store.funding_calculator

    def course_start
      "In autumn 2025" if course_start_date
    end

    def teacher_catchment_humanized
      case store["teacher_catchment"]
      when "another"
        "No"
      when "england"
        "Yes"
      end
    end

    def t(key)
      I18n.t(store[key], scope: "helpers.label.registration_wizard.#{key}_options")
    end

    def kind_of_nursery_private?
      Questionnaires::KindOfNursery::KIND_OF_NURSERY_PRIVATE_OPTIONS.include?(store["kind_of_nursery"])
    end

    def kind_of_nursery_public?
      Questionnaires::KindOfNursery::KIND_OF_NURSERY_PUBLIC_OPTIONS.include?(store["kind_of_nursery"])
    end
  end
end
