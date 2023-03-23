module Services
  module Eligibility
    class TSFCalculator
        attr_reader :institution, :course, :employment_role

        def initialize(institution:, course:, employment_role: nil)
          @institution = institution
          @course = course
          @employment_role = employment_role
        end

        def call
          if eligible_establishment_type_codes.include?(institution.establishment_type_code)
            if eligible_phase_of_education?
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
            targeted_delivery_funding: course_and_institution_eligible_for_targeted_delivery_funding?
          }
        end

        def primary_check
          {
            tsf_primary_eligibility: tsf_primary_eligibility['tsf_primary_eligibility'],
            tsf_primary_plus_eligibility: tsf_primary_eligibility['tsf_primary_plus_eligibility'],
            targeted_delivery_funding: true
          }
        end

        def tsf_primary_eligibility
          @tsf_primary_eligibility ||= Services::Eligibility::TSFPrimaryEligibility.new(
            institution:,
          ).call
        end

        def course_and_institution_eligible_for_targeted_delivery_funding?
          @course_and_institution_eligible_for_targeted_delivery_funding ||= Services::Eligibility::TargetedDeliveryFunding.new(
            institution:,
            course:,
            employment_role:,
          ).call
        end

        def eligible_phase_of_education?
          institution.establishment_type_name == "Middle deemed primary" ||
          institution.establishment_type_name == "Primary"
        end

        def eligible_establishment_type_codes
        [
          1, # Community school
          2, # Voluntary aided school
          3, # Voluntary controlled school
          5, # Foundation school
          6, # City technology college
          7, # Community special school
          8, # Non-maintained special school
          10, # Other independent special school
          12, # Foundation special school
          14, # Pupil referral unit
          15, # Local authority nursery school
          18, # Further education
          24, # Secure units
          26, # Service children's education
          28, # Academy sponsor led
          31, # Sixth form centres
          32, # Special post 16 institution
          33, # Academy special sponsor led
          34, # Academy converter
          35, # Free schools
          36, # Free schools special
          38, # Free schools alternative provision
          39, # Free schools 16 to 19
          40, # University technical college
          41, # Studio schools
          42, # Academy alternative provision converter
          43, # Academy alternative provision sponsor led
          44, # Academy special converter
          45, # Academy 16-19 converter
          46, # Academy 16 to 19 sponsor led
        ].map(&:to_s)
      end
      end
    end
  end
end
