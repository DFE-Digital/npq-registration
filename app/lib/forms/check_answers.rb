module Forms
  class CheckAnswers < Base
    include Helpers::Institution

    def previous_step
      if funding_eligbility
        :possible_funding
      else
        :funding_your_npq
      end
    end

    def next_step
      :confirmation
    end

    def after_save
      user.update!(
        trn: wizard.store["verified_trn"].presence || wizard.store["trn"],
        trn_verified: wizard.store["trn_verified"],
        trn_auto_verified: !!wizard.store["trn_auto_verified"],
        active_alert: wizard.store["active_alert"],
        full_name: wizard.store["full_name"],
        date_of_birth: wizard.store["date_of_birth"],
        national_insurance_number: ni_number_to_store,
      )

      user.applications.create!(
        course_id: course.id,
        lead_provider_id: wizard.store["lead_provider_id"],
        school_urn: institution.urn,
        ukprn: institution.ukprn,
        headteacher_status: wizard.store["headteacher_status"],
        eligible_for_funding: funding_eligbility,
        funding_choice: wizard.store["funding"],
      )

      ApplicationSubmissionJob.perform_later(user: user)

      clear_answers_in_store
    end

  private

    def funding_eligbility
      @funding_eligbility ||= Services::FundingEligibility.new(
        course: course,
        institution: institution,
        headteacher_status: wizard.store["headteacher_status"],
      ).call
    end

    def ni_number_to_store
      wizard.store["national_insurance_number"] unless wizard.store["trn_verified"]
    end

    def course
      @course ||= Course.find(wizard.store["course_id"])
    end

    def school
      @school ||= School.find_by(urn: wizard.store["school_urn"])
    end

    def user
      @user ||= User.find_by(email: wizard.store["confirmed_email"])
    end

    def clear_answers_in_store
      wizard.store.clear
    end
  end
end
