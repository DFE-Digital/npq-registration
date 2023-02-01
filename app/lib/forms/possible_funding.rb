module Forms
  class PossibleFunding < Base
    include Helpers::Institution

    def next_step
      :choose_your_provider
    end

    def previous_step
      :choose_your_npq
    end

    def course
      @course ||= Course.find_by(name: ::Course::LEGACY_NAME_MAPPING[wizard.store["choose_your_npq"]])
    end

    def message_template
      return "private_childcare_provider" if institution.is_a?(PrivateChildcareProvider)

      "school"
    end
  end
end
