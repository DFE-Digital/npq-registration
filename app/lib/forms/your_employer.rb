module Forms
  class YourEmployer < Base
    QUESTION_NAME = :employer_name

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true

    def self.permitted_params
      [QUESTION_NAME]
    end

    def question
      OpenStruct.new(
        type: :text_field,
        name: QUESTION_NAME,
        label: "What is the name of your employer?",
      )
    end

    def next_step
      :choose_your_npq
    end

    def previous_step
      :your_role
    end
  end
end
