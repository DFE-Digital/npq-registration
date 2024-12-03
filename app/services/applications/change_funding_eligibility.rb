# frozen_string_literal: true

module Applications
  class ChangeFundingEligibility
    include ActiveModel::Model
    include ActiveModel::Attributes

    OPTIONS = {
      true => I18n.t("shared.yes"),
      false => I18n.t("shared.no"),
    }.freeze

    attribute :application
    attribute :eligible_for_funding, :boolean

    validates :application, presence: true
    validates :eligible_for_funding, inclusion: OPTIONS.keys

    def eligible_for_funding_options
      OPTIONS
    end

    def change_funding_eligibility
      return false if invalid?

      funding_eligiblity_status_code =
        (eligible_for_funding ? :marked_funded_by_policy : :marked_ineligible_by_policy)

      application.update!(eligible_for_funding:, funding_eligiblity_status_code:)
    end
  end
end
