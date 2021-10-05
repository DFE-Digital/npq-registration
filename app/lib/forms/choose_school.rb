module Forms
  class ChooseSchool < Base
    include Helpers::Institution

    attr_accessor :institution_name, :institution_identifier

    validates :institution_identifier, format: { with: /\ASchool-\d{6,7}\z|\ALocalAuthority-\d+\z/, unless: -> { institution_identifier.blank? || institution_identifier == "other" } }
    validates :institution_name, length: { maximum: 64 }

    validate :validate_school_name_returns_results

    def self.permitted_params
      %i[
        institution_name
        institution_identifier
      ]
    end

    def next_step
      if institution_identifier == "other" || institution_identifier.blank?
        :choose_school
      elsif !institution(source: institution_identifier).in_england?
        :school_not_in_england
      else
        :choose_your_npq
      end
    end

    def previous_step
      :find_school
    end

    def display_schools?
      wizard.store["institution_location"].present? && wizard.store["institution_name"].present?
    end

    def possible_institutions
      return @possible_institutions if @possible_institutions

      schools = School
        .open
        .search_by_location(institution_location)
        .search_by_name(institution_name)
        .limit(10)

      local_authorities = LocalAuthority
        .search_by_location(institution_location)
        .search_by_name(institution_name)
        .limit(10)

      @possible_institutions = schools + local_authorities
    end

    def eligible_for_funding?
      Services::FundingEligibility.new(course: course, institution: institution(source: institution_identifier), headteacher_status: headteacher_status).call
    end

  private

    def headteacher_status
      wizard.store["headteacher_status"]
    end

    def course
      @course ||= Course.find(wizard.store["course_id"])
    end

    def institution_location
      wizard.store["institution_location"]
    end

    def validate_school_name_returns_results
      if display_schools? && possible_institutions.blank?
        errors.add(:institution_name, :no_results, location: institution_location, name: institution_name)
      end
    end
  end
end
