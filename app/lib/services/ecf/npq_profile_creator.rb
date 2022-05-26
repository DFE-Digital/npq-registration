module Services
  module Ecf
    class NpqProfileCreator
      attr_reader :application

      def initialize(application:)
        @application = application
      end

      def call
        profile = EcfApi::NpqProfile.new(
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
          cohort: application.cohort,
          targeted_delivery_funding_eligibility: application.targeted_delivery_funding_eligibility,
          works_in_nursery: application.works_in_nursery,
          works_in_childcare: application.works_in_childcare,
          kind_of_nursery: application.kind_of_nursery,
          private_childcare_provider_urn: application.private_childcare_provider_urn,
          funding_eligiblity_status_code: application.funding_eligiblity_status_code,
          relationships: {
            user: ecf_user,
            npq_course: ecf_npq_course,
            npq_lead_provider: ecf_npq_lead_provider,
          },
        )

        profile.save
        application.update!(ecf_id: profile.id)
      end

    private

      def user
        application.user
      end

      def ecf_user
        @ecf_user ||= EcfApi::User.new(id: application.user.ecf_id)
      end

      def ecf_npq_course
        @ecf_npq_course ||= EcfApi::NpqCourse.new(id: application.course.ecf_id)
      end

      def ecf_npq_lead_provider
        @ecf_npq_lead_provider ||= EcfApi::NpqLeadProvider.new(id: application.lead_provider.ecf_id)
      end
    end
  end
end
