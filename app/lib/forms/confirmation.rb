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

    def display_ehco_information?
      course.ehco?
    end

    def ehco_more_information_url
      "https://www.gov.uk/government/publications/national-professional-qualifications-npqs-reforms/national-professional-qualifications-npqs-reforms#additional-support-offer-for-the-npq-in-headship"
    end

    def reset_store!; end
  end
end
