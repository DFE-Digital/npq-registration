module Forms
  class IttProvider < Base
    QUESTION_NAME = :itt_provider

    attr_accessor QUESTION_NAME

    validates QUESTION_NAME, presence: true
    validate :validate_itt_provider

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        Forms::QuestionTypes::AutoCompleteIttProvider.new(name: QUESTION_NAME),
      ]
    end

    def next_step
      :choose_your_npq
    end

    def previous_step
      :employment_type
    end

  private

    def validate_itt_provider
      approved_itt_provider = ::IttProvider.currently_approved.find_by(legal_name: itt_provider)

      if approved_itt_provider.nil?
        errors.add(:itt_provider, :invalid)
      end
    end
  end
end
