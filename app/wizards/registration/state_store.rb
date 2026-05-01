module Registration
  class StateStore
    include DfE::Wizard::StateStore

    attr_reader :current_user

    def initialize(*args, current_user:, **kwargs, &block)
      @current_user = current_user

      super(*args, **kwargs, &block)
    end

    def [](key)
      data = read
      data.key?(key) ? data[key] : data[key.to_sym]
    end

    def not_starting_in_current_cohort?
      course_start_date == "no"
    end
  end
end
