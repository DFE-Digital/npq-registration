module Services
  module Eligibility
    class TargetedFunding
      attr_reader :institution, :course, :employment_role

      def self.call(institution:, course:, employment_role: nil)
        new(institution:, course:, employment_role:).call
      end

      def initialize(institution:, course:, employment_role:)
        @institution = institution
        @course = course
        @employment_role = employment_role
      end

      def call
        if institution.is_a?(School) && institution.eligible_establishment?
          if institution.primary_education_phase?
            primary_check
          else
            non_primary_check
          end
        else
          non_primary_check
        end
      end

    private

      def non_primary_check
        {
          tsf_primary_eligibility: false,
          tsf_primary_plus_eligibility: false,
          targeted_delivery_funding: targeted_delivery_funding_check?,
        }
      end

      def primary_check
        {
          tsf_primary_eligibility: tsf_primary_eligibility[:tsf_primary_eligibility],
          tsf_primary_plus_eligibility: tsf_primary_eligibility[:tsf_primary_plus_eligibility],
          targeted_delivery_funding: true,
        }
      end

      def tsf_primary_eligibility
        @tsf_primary_eligibility ||= Services::Eligibility::TsfPrimaryEligibility.call(
          institution:,
        )
      end

      def targeted_delivery_funding_check?
        @targeted_delivery_funding_check ||= Services::Eligibility::TargetedDeliveryFunding.call(
          institution:,
          course:,
          employment_role:,
        )
      end
    end
  end
end
