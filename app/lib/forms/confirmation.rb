module Forms
  class Confirmation < Base
    def requirements_met?
      wizard.store["course_id"].present? && wizard.store["lead_provider_id"].present?
    end

    def course
      Course.find_by(id: wizard.store["course_id"])
    end

    def lead_provider
      LeadProvider.find_by(id: wizard.store["lead_provider_id"])
    end

    def after_render
      wizard.store["submitted"] = true
    end

    def reset_store!; end
  end
end
