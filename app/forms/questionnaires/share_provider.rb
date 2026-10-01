module Questionnaires
  class ShareProvider < Base
    attribute :can_share_choices

    validates :can_share_choices, acceptance: true

    def self.permitted_params
      %i[
        can_share_choices
      ]
    end

    def questions
      translations = I18n.t("helpers.hint.registration_wizard.can_share_choices")

      translated_lines = translations.map do |line|
        line.include?("<a href") ? line.html_safe : line
      end

      [
        QuestionTypes::CheckBox.new(
          name: :can_share_choices,
          required: true,
          body: translated_lines,
        ),
      ]
    end

    def previous_step
      :choose_your_provider
    end

    def next_step
      if wizard.current_user&.teacher_auth_provider?
        :check_answers_and_submit
      else
        :check_answers
      end
    end
  end
end
