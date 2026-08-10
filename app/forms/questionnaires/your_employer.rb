module Questionnaires
  class YourEmployer < Base
    QUESTION_NAME = :employer_name

    attribute QUESTION_NAME

    validates QUESTION_NAME, presence: true

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        QuestionTypes::TextField.new(name: QUESTION_NAME),
      ]
    end

    def previous_step
      if query_store.employment_type_needs_employer_name?
        :your_employment
      else
        :your_role
      end
    end

    def next_step
      show_eligibility_step
    end
  end
end
