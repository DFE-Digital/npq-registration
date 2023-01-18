module Forms
  class ConfirmEmail < Base
    attr_accessor :confirmation_code

    validates :confirmation_code, presence: true, length: { is: 6 }
    validate :validate_confirmation_code_is_correct

    def self.permitted_params
      [
        :confirmation_code,
      ]
    end

    def next_step
      if changing_answer?
        :check_answers
      else
        :qualified_teacher_check
      end
    end

    def previous_step
      :contact_details
    end

    def after_save
      user = User.find_or_create_by!(email: wizard.store["email"])

      # Set the feature flag ID on the logged in user to match the session's existing ID.
      # This way the user has a smooth journey through the app and isn't suddenly swapped
      # from one A/B tested feature to another.
      user.update!(feature_flag_id: wizard.session["feature_flag_id"])

      # TODO: protect against session fixation
      wizard.session["user_id"] = user.id
      wizard.store["confirmed_email"] = user.email
      clear_entered_code
    end

  private

    def clear_entered_code
      wizard.store.delete("confirmation_code")
    end

    def validate_confirmation_code_is_correct
      if confirmation_code != wizard.store["generated_confirmation_code"]
        errors.add(:confirmation_code, :incorrect)
      end
    end
  end
end
