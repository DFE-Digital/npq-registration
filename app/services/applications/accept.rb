# frozen_string_literal: true

module Applications
  class Accept
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :application
    attribute :funded_place, :boolean

    validates :application, presence: { message: I18n.t("application.missing_application") }
    validate :not_already_accepted
    validate :cannot_change_from_rejected
    validate :other_accepted_applications_with_same_course?
    validate :eligible_for_funded_place
    validate :validate_funded_place

    def accept
      return false unless valid?

      ApplicationRecord.transaction do
        accept_application!
        reject_other_applications_in_same_cohort!
        set_funded_place_on_npq_application!
      end

      true
    end

  private

    delegate :cohort, :user, :course, to: :application

    def not_already_accepted
      return if application.blank?

      errors.add(:application, I18n.t("application.has_already_been_accepted")) if application.accepted?
    end

    def cannot_change_from_rejected
      return if application.blank?

      errors.add(:application, I18n.t("application.cannot_change_from_rejected")) if application.rejected?
    end

    def other_accepted_applications_with_same_course?
      errors.add(:application, I18n.t("application.has_another_accepted_application")) if other_accepted_applications_with_same_course.present?
    end

    def accept_application!
      application.update!(lead_provider_approval_status: "accepted")
    end

    def reject_other_applications_in_same_cohort!
      return if other_applications_in_same_cohort.blank?

      other_applications_in_same_cohort.update!(lead_provider_approval_status: "rejected")
    end

    def other_accepted_applications_with_same_course
      return if application.blank?

      @other_accepted_applications_with_same_course ||= Application
                                                          .where(lead_provider_approval_status: "accepted", course: course.rebranded_alternative_courses, user: [user, same_trn_users].flatten.compact.uniq)
                                                          .where.not(id: application.id)
    end

    def other_applications_in_same_cohort
      return if cohort.blank?

      @other_applications_in_same_cohort ||= Application
                                              .where(cohort:, course:, user:)
                                              .where.not(id: application.id)
    end

    def trn
      @trn ||= user.trn_verified? ? user.trn : nil
    end

    def same_trn_users
      return if trn.blank?

      @same_trn_users ||= User
                         .where(trn:)
                         .where.not(id: user.id)
    end

    def set_funded_place_on_npq_application!
      return unless cohort&.funding_cap?

      application.update!(funded_place:)
    end

    def eligible_for_funded_place
      return if errors.any?
      return unless cohort&.funding_cap?

      if funded_place && !application.eligible_for_funding
        errors.add(:application, I18n.t("application.not_eligible_for_funded_place"))
      end
    end

    def validate_funded_place
      return if errors.any?
      return unless cohort&.funding_cap?

      if funded_place.nil?
        errors.add(:application, I18n.t("application.funded_place_required"))
      end
    end
  end
end
