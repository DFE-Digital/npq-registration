module Forms
  class ChooseAnNpqAndProvider < Base
    def previous_step
      :provider_check
    end

    def next_step; end
  end
end
