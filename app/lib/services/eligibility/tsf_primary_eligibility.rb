module Services
  module Eligibility
    class TSFPrimaryEligibility
        attr_reader :institution

        def initialize(institution:)
          @institution = institution
        end

        def call
          {
            tsf_primary_eligibility: true,
            tsf_primary_plus_eligibility: under_pupil_count_threshold?,
          }
        end

      private

        def under_pupil_count_threshold?
          return false if institution.number_of_pupils.nil?
          return false if institution.number_of_pupils.zero?

          institution.pupil_count <=150
        end
      end
    end
  end
end
