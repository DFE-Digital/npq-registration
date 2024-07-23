# frozen_string_literal: true

module Applications
  class Accept
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :application
    attribute :funded_place
    attribute :schedule_identifier, :string

    validates :application, presence: true
    validates :funded_place, inclusion: { in: [true, false], if: :validate_funded_place? }
    validate :not_already_accepted
    validate :cannot_change_from_rejected
    validate :other_accepted_applications_with_same_course?
    validate :eligible_for_funded_place
    validate :validate_permitted_schedule_for_course

    def accept
      return false unless valid?

      ApplicationRecord.transaction do
        accept_application!
        create_application_state!
        reject_other_applications_in_same_cohort!
      end

      true
    end

  private

    delegate :cohort, :user, :course, :lead_provider,
             to: :application

    def not_already_accepted
      return if application.blank?

      errors.add(:application, :has_already_been_accepted) if application.accepted?
    end

    def cannot_change_from_rejected
      return if application.blank?

      errors.add(:application, :cannot_change_from_rejected) if application.rejected?
    end

    def other_accepted_applications_with_same_course?
      errors.add(:application, :has_another_accepted_application) if other_accepted_applications_with_same_course.present?
    end

    def accept_application!
      opts = {
        lead_provider_approval_status: "accepted",
        schedule:,
      }

      if cohort&.funding_cap?
        opts[:funded_place] = funded_place
      end

      application.update!(opts)
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

    def eligible_for_funded_place
      return if errors.any?
      return unless cohort&.funding_cap?

      if funded_place && !application.eligible_for_funding
        errors.add(:application, :not_eligible_for_funded_place)
      end
    end

    def validate_funded_place?
      errors.blank? && cohort&.funding_cap?
    end

    def schedule
      @schedule ||= Schedule.where(identifier: schedule_identifier, cohort:).first || fallback_schedule
    end

    def fallback_schedule
      course.schedule_for(cohort:)
    end

    def validate_permitted_schedule_for_course
      return if errors.any?
      return if schedule_identifier.blank?
      return unless schedule

      unless schedule.course_group.courses.include?(course)
        errors.add(:schedule_identifier, :invalid_for_course)
      end
    end

    def create_application_state!
      ApplicationState.create!(
        application:,
        lead_provider:,
        state: "active",
      )
    end
  end
end
