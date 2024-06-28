module Ecf
  class NpqProfileCreator
    attr_reader :application

    def initialize(application:)
      @application = application
    end

    def call
      profile = External::EcfAPI::NpqProfile.new(
        teacher_reference_number: user.trn,
        teacher_reference_number_verified: user.trn_verified,
        active_alert: user.active_alert,
        date_of_birth: user.date_of_birth,
        national_insurance_number: user.national_insurance_number,
        school_urn: application.school_urn,
        school_ukprn: application.ukprn,
        headteacher_status: application.headteacher_status,
        eligible_for_funding: application.eligible_for_funding,
        funding_choice: application.funding_choice,
        works_in_school: application.works_in_school,
        employer_name: application.employer_name,
        employment_role: application.employment_role,
        employment_type: application.employment_type,
        targeted_delivery_funding_eligibility: application.targeted_delivery_funding_eligibility,
        works_in_childcare: application.works_in_childcare,
        kind_of_nursery: application.kind_of_nursery,
        private_childcare_provider_urn: application.private_childcare_provider&.provider_urn,
        funding_eligiblity_status_code: application.funding_eligiblity_status_code,
        teacher_catchment: application.teacher_catchment,
        teacher_catchment_country: application.teacher_catchment_country,
        itt_provider: application.itt_provider&.legal_name,
        lead_mentor: application.lead_mentor,
        primary_establishment: application.primary_establishment,
        number_of_pupils: application.number_of_pupils,
        tsf_primary_plus_eligibility: application.tsf_primary_plus_eligibility,
        relationships: {
          user: ecf_user,
          npq_course: ecf_npq_course,
          npq_lead_provider: ecf_npq_lead_provider,
        },
      )

      # JsonApiClient::Resource uses errors for flow control, so failed saves
      # will divert to the rescue block below
      # I'd prefer to use the return value of save, but that's not possible
      profile.save

      application.update!(
        ecf_id: profile.id,
        teacher_catchment_synced_to_ecf: true,
      )

      EcfSyncRequestLog.create!(
        sync_type: :application_creation,
        syncable: application,
        status: :success,
      )
    rescue StandardError => e
      env = e.try(:env) || {}
      response_body = env["response_body"]
      EcfSyncRequestLog.create!(
        sync_type: :application_creation,
        syncable: application,
        status: :failed,
        error_messages: ["#{e.class} - #{e.message}"],
        response_body:,
      )
      return if e.is_a?(JsonApiClient::Errors::ConnectionError)

      Sentry.with_scope do |scope|
        scope.set_context("Application", { id: application.id })
        Sentry.capture_exception(e)

        # Re-raise to fail the sync, we'll want to retry again later
        raise e
      end
    end

  private

    def user
      application.user
    end

    def ecf_user
      @ecf_user ||= External::EcfAPI::User.new(id: application.user.ecf_id)
    end

    def ecf_npq_course
      @ecf_npq_course ||= External::EcfAPI::NpqCourse.new(id: application.course.ecf_id)
    end

    def ecf_npq_lead_provider
      @ecf_npq_lead_provider ||= External::EcfAPI::NpqLeadProvider.new(id: application.lead_provider.ecf_id)
    end
  end
end
