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
      wizard.session["clear_tra_login"] = true if wizard.tra_get_an_identity_omniauth_integration_active?
    end

    def display_npqh_information?
      course.npqh?
    end

    def ehco_more_information_url
      "https://www.gov.uk/government/publications/national-professional-qualifications-npqs-reforms/national-professional-qualifications-npqs-reforms#additional-support-offer-for-the-npq-in-headship"
    end

    def reset_store!; end
  end
end
