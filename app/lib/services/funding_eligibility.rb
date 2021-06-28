module Services
  class FundingEligibility
    attr_reader :course, :school

    def initialize(course:, school:)
      @course = course
      @school = school
    end

    def call
      case course.name
      when "NPQ Leading Teaching (NPQLT)",
           "NPQ Leading Behaviour and Culture (NPQLBC)",
           "NPQ for Senior Leadership (NPQSL)",
           "NPQ for Executive Leadership (NPQEL)"
        eligible_establishment_type_codes_for_base_courses.include?(school.establishment_type_code) && school.high_pupil_premium
      when "NPQ Leading Teacher Development (NPQLTD)",
           "NPQ for Headship (NPQH)"
        eligible_establishment_type_codes_for_ltd_or_headship_courses.include?(school.establishment_type_code)
      else # fail safe
        false
      end
    end

  private

    def eligible_establishment_type_codes_for_base_courses
      %w[1 2 3 5 6 7 8 12 14 28 33 34 35 36 38 40 41 42 43 44].freeze
    end

    def eligible_establishment_type_codes_for_ltd_or_headship_courses
      %w[1 2 3 5 6 7 8 12 14 15 28 33 34 35 36 38 39 40 41 42 44 45].freeze
    end
  end
end
