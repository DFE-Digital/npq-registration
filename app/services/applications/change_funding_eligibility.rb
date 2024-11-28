# frozen_string_literal: true

module Applications
  class ChangeFundingEligibility
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :application
    attribute :eligible_for_funding, :boolean

    validates :eligible_for_funding, inclusion: [true, false]
    validates :application, presence: true

    def change_funding_eligibility
      Application.transaction do
        return false if invalid?

        application.update!(eligible_for_funding:)
      end
    end
  end
end
