module Services
  class FundingEligibility
    attr_reader :institution, :course

    def initialize(institution:, course:, new_headteacher: false)
      @institution = institution
      @course = course
      @new_headteacher = new_headteacher
    end

    def call
      return false if institution.nil?
      return true if eligible_urns.include?(institution.urn)

      case institution.class.name
      when "School"
        if course.aso?
          eligible_establishment_type_codes.include?(institution.establishment_type_code) && new_headteacher?
        else
          eligible_establishment_type_codes.include?(institution.establishment_type_code)
        end
      when "LocalAuthority"
        true
      else
        false
      end
    end

  private

    def new_headteacher?
      @new_headteacher
    end

    def eligible_establishment_type_codes
      %w[1 2 3 5 6 7 8 12 14 15 18 24 26 28 31 32 33 34 35 36 38 39 40 41 42 43 44 45 46].freeze
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
