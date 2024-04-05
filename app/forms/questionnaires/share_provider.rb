module Questionnaires
  class ShareProvider < Base
    attr_accessor :can_share_choices

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

    def next_step
      :check_answers
    end

    def previous_step
      :choose_your_provider
    end
  end
end
