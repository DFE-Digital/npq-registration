module Forms
  class GetAnIdentityCallback < Base
    def skip_step?
      true
    end

    def next_step
      after_login_next_step
    end

    def previous_step
      :start
    end
  end
end
