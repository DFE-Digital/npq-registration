module Forms
  class Start < Base
    def requirements_met?
      true
    end

    def next_step
      :provider_check
    end
  end
end
