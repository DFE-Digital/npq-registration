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
        first_name: wizard.store["first_name"],
        last_name: wizard.store["last_name"],
      )
    end
  end
end
