module Forms
  class Confirmation < Base
    def requirements_met?
      true
    end

    def course
      Course.find_by(id: wizard.store["course_id"])
    end

    def lead_provider
      LeadProvider.find_by(id: wizard.store["lead_provider_id"])
    end

    def after_render
      wizard.store.clear
    end
  end
end
