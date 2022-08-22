module Forms
  class YourRole < Base
    QUESTION_NAME = :employment_role

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true

    def self.permitted_params
      [QUESTION_NAME]
    end

    def question
      OpenStruct.new(
        type: :text_field,
        name: QUESTION_NAME,
        label: I18n.t("registration_wizard.your_role.label"),
        hint: I18n.t("registration_wizard.your_role.hint"),
      )
    end

    def next_step
      :your_employer
    end

    def previous_step
      :your_employment
    end
  end
end
