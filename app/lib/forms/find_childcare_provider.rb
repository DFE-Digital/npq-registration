module Forms
  class FindChildcareProvider < Base
    attr_accessor :institution_location

    validates :institution_location, presence: true, length: { maximum: 64 }

    def self.permitted_params
      %i[
        institution_location
      ]
    end

    def next_step
      :choose_childcare_provider
    end

    def previous_step
      :qualified_teacher_check
    end
  end
end
