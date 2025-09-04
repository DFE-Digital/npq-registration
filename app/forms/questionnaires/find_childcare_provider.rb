module Questionnaires
  class FindChildcareProvider < Base
    QUESTION_NAME = :institution_location

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true, length: { maximum: 64 }

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        QuestionTypes::TextField.new(
          name: QUESTION_NAME,
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
