module Forms
  class ITTProvider < Base
    QUESTION_NAME = :itt_provider

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true

    def self.permitted_params
      [QUESTION_NAME]
    end

    def question
      Forms::QuestionTypes::TextField.new(name: QUESTION_NAME)
    end

    def next_step
      if approved_itt_provider # check if its the NPQLTD course
        :choose_your_npq
      end
    end

    def previous_step
      :employment_type
    end

  private

    def approved_itt_provider
      # look up the provider infomration
    end
  end
end
