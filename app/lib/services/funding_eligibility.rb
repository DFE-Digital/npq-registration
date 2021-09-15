module Services
  class FundingEligibility
    attr_reader :course, :institution, :headteacher_status

    def initialize(course:, institution:, headteacher_status: nil)
      @course = course
      @institution = institution
      @headteacher_status = headteacher_status
    end

    def call
      return true if eligible_urns.include?(institution.urn)

      case institution.class.name
      when "School"
        case course.name
        when "NPQ Leading Teaching (NPQLT)",
             "NPQ Leading Behaviour and Culture (NPQLBC)",
             "NPQ for Senior Leadership (NPQSL)",
             "NPQ for Executive Leadership (NPQEL)"
          eligible_establishment_type_codes_for_base_courses.include?(institution.establishment_type_code) && institution.high_pupil_premium
        when "NPQ Leading Teacher Development (NPQLTD)"
          eligible_establishment_type_codes_for_ltd_courses.include?(institution.establishment_type_code)
        when "NPQ for Headship (NPQH)"
          eligible_new_headteacher = if %w[yes_in_first_two_years yes_when_course_starts].include?(headteacher_status)
                                       eligible_establishment_type_codes_for_new_headship.include?(institution.establishment_type_code)
                                     end

          eligible_headship_institution = institution.high_pupil_premium && eligible_establishment_type_codes_for_headship_and_high_pupil_premiums.include?(institution.establishment_type_code)

          eligible_new_headteacher || eligible_headship_institution
        else # fail safe
          false
        end
      when "LocalAuthority"
        case course.name
        when "NPQ Leading Teacher Development (NPQLTD)",
             "NPQ for Headship (NPQH)"
          true
        when "NPQ Leading Teaching (NPQLT)",
             "NPQ Leading Behaviour and Culture (NPQLBC)",
             "NPQ for Senior Leadership (NPQSL)",
             "NPQ for Executive Leadership (NPQEL)"
          institution.high_pupil_premium
        else
          false
        end
      else
        false
      end
    end

  private

    def eligible_establishment_type_codes_for_base_courses
      %w[1 2 3 5 6 7 8 12 14 28 33 34 35 36 38 40 41 42 43 44].freeze
    end

    def eligible_establishment_type_codes_for_ltd_courses
      %w[1 2 3 5 6 7 8 12 14 15 28 33 34 35 36 38 39 40 41 42 43 44 45].freeze
    end

    def eligible_establishment_type_codes_for_headship_and_high_pupil_premiums
      %w[1 2 3 5 6 7 8 12 14 28 33 34 35 36 38 40 41 42 43 44].freeze
    end

    def eligible_establishment_type_codes_for_new_headship
      %w[1 2 3 5 6 7 8 12 14 15 28 33 34 35 36 38 39 40 41 42 43 44 45].freeze
    end

    def eligible_urns
      %w[
        146816
        141030
        131867
        130416
        145003
        139730
        143704
        141940
        147756
        139363
        130468
        130457
        144753
        144886
        130503
        143689
        144511
        130452
        130548
        145002
        144463
        130458
        130411
        130422
        130746
        133608
        144887
        145230
        139433
        142673
        147477
        130580
        133545
        130504
      ]
    end
  end
end
