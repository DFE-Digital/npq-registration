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
