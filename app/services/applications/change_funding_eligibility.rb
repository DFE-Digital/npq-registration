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

    validate  :validate_funding_eligiblity_status_code_change, if: :application
    validate  :validate_funding_eligiblity_status_with_funded_place, if: :application

    def eligible_for_funding_options
      OPTIONS
    end

    def change_funding_eligibility
      return false if invalid?

      funding_eligiblity_status_code =
        (eligible_for_funding ? :marked_funded_by_policy : :marked_ineligible_by_policy)

      application.update!(eligible_for_funding:, funding_eligiblity_status_code:).tap do
        send_eligible_for_funding_email if application.saved_changes["eligible_for_funding"] == [false, true]
      end
    end

  private

    def validate_funding_eligiblity_status_code_change
      if declared_as_billable_or_changeable? && eligible_for_funding == false
        errors.add(:base, :declaration_exists)
      end
    end

    def validate_funding_eligiblity_status_with_funded_place
      if !eligible_for_funding && application.funded_place
        errors.add(:base, :funded_application)
      end
    end

    def declared_as_billable_or_changeable?
      application.declarations.billable_or_changeable.count.positive?
    end

    def send_eligible_for_funding_email
      ApplicationFundingEligibilityMailer.eligible_for_funding_mail(
        to: application.user.email,
        full_name: application.user.full_name,
        provider_name: application.lead_provider.name,
        course_name: application.course.name,
        ecf_id: application.ecf_id,
      ).deliver_later
    end
  end
end
