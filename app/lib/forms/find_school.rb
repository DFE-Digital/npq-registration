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
      if wizard.tra_get_an_identity_omniauth_integration_active?
        :teacher_reference_number
      else
        :qualified_teacher_check
      end
    end
  end
end
