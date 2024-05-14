module Questionnaires
  class SencoStartDate < Base
    include ActiveModel::Attributes
    include ActiveRecord::AttributeAssignment
    include Helpers::Institution

    QUESTION_NAME = :senco_start_date

    attribute QUESTION_NAME, :date

    validates QUESTION_NAME, presence: true

    def self.permitted_params
      [QUESTION_NAME]
    end

    def questions
      [
        QuestionTypes::DateField.new(
          name: :senco_start_date,
          style_options: { omit_day: true },
        ),
      ]
    end

    def next_step
      if !wizard.query_store.teacher_catchment_england?
        :ineligible_for_funding
      else
        :funding_eligibility_senco
      end
    end

    def previous_step
      :senco_in_role
    end
  end
end
