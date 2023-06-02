module Forms
  class Confirmation < Base
    def requirements_met?
      course.present? && wizard.store["lead_provider_id"].present?
    end

    def course
      wizard.query_store.course
    end

    def lead_provider
      LeadProvider.find_by(id: wizard.store["lead_provider_id"])
    end

    def after_render
      wizard.store["submitted"] = true
      wizard.session["clear_tra_login"] = true
    end

    def display_npqh_information?
      course.npqh?
    end

    def ehco_more_information_url
      "https://www.gov.uk/government/publications/national-professional-qualifications-npqs-reforms/national-professional-qualifications-npqs-reforms#additional-support-offer-for-the-npq-in-headship"
    end

    def reset_store!; end

    def next_step; end
  end
end
