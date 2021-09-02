module Forms
  class FindSchool < Base
    attr_accessor :institution_location

    validates :institution_location, presence: true, length: { maximum: 64 }

    def self.permitted_params
      %i[
        institution_location
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
