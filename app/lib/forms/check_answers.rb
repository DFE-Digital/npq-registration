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
      )

      user.applications.create!(
        course_id: wizard.store["course_id"],
        lead_provider_id: wizard.store["lead_provider_id"],
        school_urn: wizard.store["school_urn"],
        headerteacher_over_two_years: wizard.store["headerteacher_over_two_years"],
      )
    end
  end
end
