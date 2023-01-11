module Forms
  class IttProvider < Base
    QUESTION_NAME = :itt_provider

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true

    def self.permitted_params
      [QUESTION_NAME]
    end

    def question
      Forms::QuestionTypes::AutoCompleteIttProvider.new(name: QUESTION_NAME)
    end

    def next_step
      if approved_itt_provider?
        :choose_your_npq
      end
    end

    def previous_step
      :employment_type
    end

  private

    def approved_itt_provider?
      ::IttProvider.currently_approved.find_by(legal_name: itt_provider).present?
    end
  end
end
