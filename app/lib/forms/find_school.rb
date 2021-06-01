module Forms
  class FindSchool < Base
    attr_accessor :school_location

    validates :school_location, presence: true

    def self.permitted_params
      %i[
        school_location
      ]
    end

    def next_step
      :choose_school
    end

    def previous_step
      :choose_your_provider
    end
  end
end
