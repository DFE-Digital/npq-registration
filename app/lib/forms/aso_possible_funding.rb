module Forms
  class AsoPossibleFunding < Base
    def next_step
      :choose_your_provider
    end

    def previous_step
      :aso_new_headteacher
    end

    def course
      @course ||= Course.find_by(name: ::Course::LEGACY_NAME_MAPPING[wizard.store["choose_your_npq"]])
    end
  end
end
