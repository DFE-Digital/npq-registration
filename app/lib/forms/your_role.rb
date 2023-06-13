module Forms
  class YourRole < Base
    QUESTION_NAME = :employment_role

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        Forms::QuestionTypes::TextField.new(name: QUESTION_NAME),
      ]
    end

    def next_step
      :your_employer
    end

    def previous_step
      :your_employment
    end
  end
end
