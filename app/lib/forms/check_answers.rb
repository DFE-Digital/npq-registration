module Forms
  class CheckAnswers < Base
    def previous_step
      :choose_school
    end

    def next_step
      :confirmation
    end

    def after_save
      user = User.find_by(email: wizard.store["email"])

      user.update!(
        trn: wizard.store["trn"],
        full_name: wizard.store["full_name"],
        date_of_birth: wizard.store["date_of_birth"],
      )

      user.applications.create!(
        course_id: wizard.store["course_id"],
        lead_provider_id: wizard.store["lead_provider_id"],
        school_urn: wizard.store["school_urn"],
        headteacher_status: wizard.store["headteacher_status"],
      )

      ApplicationSubmissionJob.perform_now(user: user)
    end
  end
end
