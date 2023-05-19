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
          label: { text: "Where is your workplace located?" },
          hint: { text: "Enter the town, city or the first part of the postcode. For example Chester or CH1." },
          width: "three-quarters",
        },
      )
    end

    def next_step
      :choose_school
    end

    def previous_step
      if wizard.tra_get_an_identity_omniauth_integration_active?
        :work_setting
      else
        :qualified_teacher_check
      end
    end
  end
end
