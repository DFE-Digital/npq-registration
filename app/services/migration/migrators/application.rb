module Migration::Migrators
  class Application < Base
    ATTRIBUTES = %w[
      headteacher_status
      eligible_for_funding
      funding_choice
      works_in_school
      employer_name
      employment_role
      targeted_support_funding_eligibility
      teacher_catchment_iso_country_code
      works_in_nursery
      works_in_childcare
      kind_of_nursery
      targeted_delivery_funding_eligibility
      funding_eligiblity_status_code
      employment_type
      lead_mentor
      primary_establishment
      number_of_pupils
      tsf_primary_eligibility
      tsf_primary_plus_eligibility
      lead_provider_approval_status
      teacher_catchment
      teacher_catchment_country
      notes
      funded_place
      created_at
      updated_at
    ].freeze

    class << self
      def record_count
        ecf_npq_applications.count
      end

      def model
        :application
      end

      def dependencies
        %i[private_childcare_provider itt_provider cohort lead_provider schedule course user school]
      end

      def ecf_npq_applications
        Migration::Ecf::NpqApplication
          .joins(:participant_identity)
          .includes(:user, profile: :schedule)
      end

      def records_per_worker
        (super / 2.0).ceil
      end
    end

    def call
      applications_by_ecf_id = ::Application.where(ecf_id: self.class.ecf_npq_applications.pluck(:id)).index_by(&:ecf_id)

      migrate(self.class.ecf_npq_applications) do |ecf_npq_application|
        application = applications_by_ecf_id[ecf_npq_application.id]

        application ||= ::Application.new(ecf_id: ecf_npq_application.id)

        application.cohort_id = find_cohort_id!(ecf_id: ecf_npq_application.cohort_id)
        application.itt_provider_id = find_itt_provider_id!(itt_provider: ecf_npq_application.itt_provider) if ecf_npq_application.itt_provider
        application.private_childcare_provider_id = find_private_childcare_provider_id!(provider_urn: ecf_npq_application.private_childcare_provider_urn) if ecf_npq_application.private_childcare_provider_urn
        application.ukprn = ecf_npq_application.school_ukprn

        school_urn = ecf_profile_school_urn_or_ecf_npq_application_school_urn?(ecf_npq_application)
        if school_urn
          application.school_id = find_school_id(urn: school_urn)
        end

        application.lead_provider_id = find_lead_provider_id!(ecf_id: ecf_npq_application.npq_lead_provider_id)
        application.course_id = find_course_id!(ecf_id: ecf_npq_application.npq_course_id)

        if ecf_npq_application.profile
          ecf_schedule = ecf_npq_application.profile.schedule
          application.schedule_id = find_schedule_id!(ecf_id: ecf_schedule.id) if ecf_schedule

          application.training_status = ecf_npq_application.profile.training_status
          application.accepted_at = ecf_npq_application.profile.created_at
        end

        application.user_id = find_user_id!(ecf_id: ecf_npq_application.user.id)
        application.version_note = "Changes migrated from ECF to NPQ"

        attrs = ecf_npq_application.attributes.slice(*ATTRIBUTES).merge(skip_touch_user_if_changed: true)

        if touch_updated_at?(application, ecf_npq_application)
          attrs["updated_at"] = Time.zone.now
        end

        application.update!(attrs)
      end
    end

    def run_once_post_migration
      report_applications_not_in_ecf_as_failures
      backfill_ecf_ids
      backfill_cohorts
      backfill_lead_provider_approval_statuses
    end

  private

    def touch_updated_at?(application, ecf_npq_application)
      if ecf_npq_application.itt_provider.nil? && application.itt_provider_including_disabled.present?
        return true
      end

      if ecf_npq_application.private_childcare_provider_urn.nil? && application.private_childcare_provider_including_disabled.present?
        return true
      end

      if ecf_npq_application.profile&.school_urn.presence != ecf_npq_application.school_urn
        return true
      end

      user_trn = find_user_trn(ecf_id: ecf_npq_application.user.id)

      if ecf_npq_application.lead_provider_approval_status == "accepted"
        if user_trn != ecf_npq_application&.user&.teacher_profile&.trn
          return true
        end
      elsif user_trn != ecf_npq_application.teacher_reference_number
        return true
      end

      false
    end

    def ecf_profile_school_urn_or_ecf_npq_application_school_urn?(ecf_npq_application)
      ecf_npq_application.profile&.school_urn.presence || ecf_npq_application.school_urn
    end

    def report_applications_not_in_ecf_as_failures
      applications_not_in_ecf = ::Application.where.not(ecf_id: self.class.ecf_npq_applications.pluck(:id)).select(:id)
      applications_not_in_ecf.each { |a| failure_manager.record_failure(a, "NPQApplication not found in ECF") }
    end

    def backfill_ecf_ids
      ::Application.where(ecf_id: nil).find_each do |application|
        version_note = "Changes migrated from ECF to NPQ"
        application.update!(ecf_id: SecureRandom.uuid, version_note:)
      end
    end

    def backfill_cohorts
      ::Application.where(cohort_id: nil).find_each do |application|
        version_note = "Changes migrated from ECF to NPQ"
        fallback_cohort = application&.schedule&.cohort || ::Cohort.current
        application.update!(cohort: fallback_cohort, version_note:)
      end
    end

    def backfill_lead_provider_approval_statuses
      ::Application.where(lead_provider_approval_status: nil).find_each do |application|
        version_note = "Changes migrated from ECF to NPQ"
        application.update!(lead_provider_approval_status: "pending", version_note:)
      end
    end
  end
end
