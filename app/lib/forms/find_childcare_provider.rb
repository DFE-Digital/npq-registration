module Forms
  class FindChildcareProvider < Base
    QUESTION_NAME = :institution_location

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true, length: { maximum: 64 }

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        Forms::QuestionTypes::TextField.new(
          name: QUESTION_NAME,
          locale_name: :find_childcare_provider,
        ),
      ]
    end

    def next_step
      :choose_childcare_provider
    end

    def previous_step
      :kind_of_nursery
    end
  end
end
