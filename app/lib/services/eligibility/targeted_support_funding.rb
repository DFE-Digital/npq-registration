module Services
  module Eligibility
    class TargetedSupportFunding
      attr_reader :institution

      def initialize(institution:)
        @institution = institution
      end

      def call
        return false if institution.nil?
        return false if institution.is_a?(LocalAuthority)
        return false if institution.number_of_pupils.nil?
        return false if institution.number_of_pupils.zero?

        eligible_establishment_type_codes.include?(institution.establishment_type_code) &&
          institution.number_of_pupils < pupil_count_threshold
      end

    private

      def pupil_count_threshold
        600
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
