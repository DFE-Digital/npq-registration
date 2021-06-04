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
    end
  end
end
