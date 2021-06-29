module Forms
  class CheckAnswers < Base
    def previous_step
      :choose_school
    end

    def next_step
      :confirmation
    end

    def after_save
      user.update!(
        trn: wizard.store["trn"],
        trn_verified: wizard.store["trn_verified"],
        active_alert: wizard.store["active_alert"],
        full_name: wizard.store["full_name"],
        date_of_birth: wizard.store["date_of_birth"],
      )

      user.applications.create!(
        course_id: course.id,
        lead_provider_id: wizard.store["lead_provider_id"],
        school_urn: school.urn,
        headteacher_status: wizard.store["headteacher_status"],
        eligible_for_funding: Services::FundingEligibility.new(
          course: course,
          school: school,
          headteacher_status: wizard.store["headteacher_status"],
        ).call,
        funding_choice: wizard.store["funding"],
      )

      ApplicationSubmissionJob.perform_later(user: user)

      clear_answers_in_store
    end

  private

    def course
      @course ||= Course.find(wizard.store["course_id"])
    end

    def school
      @school ||= School.find_by(urn: wizard.store["school_urn"])
    end

    def user
      @user ||= User.find_by(email: wizard.store["email"])
    end

    def clear_answers_in_store
      wizard.store.clear
    end
  end
end
