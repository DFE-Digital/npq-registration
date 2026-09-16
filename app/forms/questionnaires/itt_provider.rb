module Questionnaires
  class IttProvider < Base
    QUESTION_NAME = :itt_provider

    attribute QUESTION_NAME

    validates QUESTION_NAME, presence: true
    validate :validate_itt_provider

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        QuestionTypes::AutoCompleteIttProvider.new(name: QUESTION_NAME),
      ]
    end

    def previous_step
      :your_employment
    end

    def next_step
      if eligible_for_funding?
        if query_store.course.ehco?
          :ehco_possible_funding
        else
          :possible_funding
        end
      else
        :ineligible_for_funding
      end
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
