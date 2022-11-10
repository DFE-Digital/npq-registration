module Forms
  class Start < Base
    def requirements_met?
      true
    end

    def next_step
      if wizard.tra_get_an_identity_omniauth_integration_active?
        :teacher_reference_number
      else
        :provider_check
      end
    end
  end
end
