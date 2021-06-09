module Forms
  class ChooseSchool < Base
    attr_accessor :school_name, :school_urn

    validates :school_urn, format: { with: /\A\d{6}\z/, unless: -> { school_urn.blank? || school_urn == "other" } }
    validates :school_name, length: { maximum: 64 }

    validate :validate_school_name_returns_results

    def self.permitted_params
      %i[
        school_name
        school_urn
      ]
    end

    def next_step
      if school_urn == "other" || school_urn.blank?
        :choose_school
      elsif !school.in_england?
        :school_not_in_england
      else
        :check_answers
      end
    end

    def previous_step
      :find_school
    end

    def display_schools?
      wizard.store["school_location"].present? && wizard.store["school_name"].present?
    end

    def possible_schools
      @possible_schools ||= School
        .open
        .search_by_location(school_location)
        .search_by_name(school_name)
        .limit(10)
    end

  private

    def school
      @school ||= School.find_by(urn: school_urn)
    end

    def school_location
      wizard.store["school_location"]
    end

    def validate_school_name_returns_results
      if display_schools? && possible_schools.blank?
        errors.add(:school_name, :no_results, location: school_location, name: school_name)
      end
    end
  end
end
