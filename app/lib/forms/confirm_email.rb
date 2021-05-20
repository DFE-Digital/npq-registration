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
      :qualified_teacher_check
    end

    def previous_step
      :contact_details
    end

  private

    def validate_confirmation_code_is_correct
      if confirmation_code != wizard.store["generated_confirmation_code"]
        errors.add(:confirmation_code, :incorrect)
      end
    end
  end
end
