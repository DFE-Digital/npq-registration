module Eligibility
  class TsfPrimaryEligibility
    attr_reader :institution

    def self.call(institution:)
      new(institution:).call
    end

    def initialize(institution:)
      @institution = institution
    end

    def call
      {
        tsf_primary_eligibility: institution.primary_education_phase?,
        tsf_primary_plus_eligibility: under_pupil_count_threshold?,
      }
    end

  private

    def under_pupil_count_threshold?
      return false unless institution.primary_education_phase?
      return false if institution.number_of_pupils.nil?
      return false if institution.number_of_pupils.zero?

      institution.number_of_pupils <= 150
    end
  end
end
