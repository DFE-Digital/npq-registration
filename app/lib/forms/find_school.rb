module Forms
  class FindSchool < Base
    attr_accessor :institution_location

    validates :institution_location, presence: true, length: { maximum: 64 }

    def self.permitted_params
      %i[
        institution_location
      ]
    end

    def question
      @question ||= QuestionTypes::TextField.new(
        name: :institution_location,
        form: self,
        style_options: {
          label: { text: I18n.t("helpers.title.registration_wizard.institution_location") },
          hint: { text: I18n.t("helpers.hint.registration_wizard.institution_location") },
          width: "three-quarters",
        },
      )
    end

    def next_step
      :choose_school
    end

    def previous_step
      :work_setting
    end
  end
end
