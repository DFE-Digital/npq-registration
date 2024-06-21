module Questionnaires
  class YourEmployer < Base
    QUESTION_NAME = :employer_name

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        QuestionTypes::TextField.new(name: QUESTION_NAME),
      ]
    end

    def next_step
      :choose_your_npq
    end

    def previous_step
      if query_store.employment_type_hospital_school? || query_store.young_offender_institution?
        :your_employment
      else
        :your_role
      end
    end
  end
end
