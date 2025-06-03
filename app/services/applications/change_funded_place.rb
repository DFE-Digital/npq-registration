# frozen_string_literal: true

module Applications
  class ChangeFundedPlace
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :application
    attribute :funded_place

    validates :application, presence: true
    validates :funded_place, inclusion: { in: [true, false] }
    validate :accepted_application
    validate :eligible_for_funding
    validate :cohort_has_funding_cap
    validate :eligible_for_changing_funded_place

    def change
      return false unless valid?

      application.update!(funded_place:)
      application.reload
    end

  private

    delegate :cohort, to: :application

    def accepted_application
      return if application&.accepted_lead_provider_approval_status?

      errors.add(:application, :cannot_change_funded_status_from_non_accepted)
    end

    def eligible_for_funding
      return unless funded_place
      return if application.eligible_for_funding?

      errors.add(:application, :cannot_change_funded_status_non_eligible)
    end

    def cohort_has_funding_cap
      return if errors.any?
      return if cohort&.funding_cap?

      errors.add(:application, :cohort_does_not_accept_capping)
    end

    def eligible_for_changing_funded_place
      return unless application&.declarations&.billable_or_changeable&.any?

      errors.add(:application, :cannot_change_funded_place)
    end
  end
end
