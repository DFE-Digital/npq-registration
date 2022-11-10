module Forms
  class GetAnIdentityCallback < Base
    def skip_step?
      true
    end

    def next_step
      :provider_check
    end

    def previous_step
      :get_an_identity
    end
  end
end
