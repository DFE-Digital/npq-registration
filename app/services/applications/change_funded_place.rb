# frozen_string_literal: true

module Applications
  class ChangeFundedPlace
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :application
    attribute :funded_place

    validates :application, presence: { message: I18n.t("application.missing_application") }
    validates :funded_place,
              inclusion: {
                in: [true, false],
                message: I18n.t("application.missing_funded_place"),
              }
    validate :accepted_application
    validate :eligible_for_funding
    validate :cohort_has_funding_cap
    validate :eligible_for_removing_funding_place

    def change
      return false unless valid?

      application.update!(funded_place:)
    end

  private

    delegate :cohort, to: :application

    def accepted_application
      return if application.accepted?

      errors.add(:application, I18n.t("application.cannot_change_funded_status_from_non_accepted"))
    end

    def eligible_for_funding
      return unless funded_place
      return if application.eligible_for_funding?

      errors.add(:application, I18n.t("application.cannot_change_funded_status_non_eligible"))
    end

    def cohort_has_funding_cap
      return if errors.any?
      return if cohort&.funding_cap?

      errors.add(:application, I18n.t("application.cohort_does_not_accept_capping"))
    end

    def eligible_for_removing_funding_place
      return if funded_place
      return unless application.declarations.billable_or_changeable.any?

      errors.add(:application, I18n.t("application.cannot_change_funded_place"))
    end
  end
end
