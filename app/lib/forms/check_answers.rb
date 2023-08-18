module Forms
  class CheckAnswers < Base
    include Helpers::Institution

    def previous_step
      :share_provider
    end

    def next_step; end

    def last_step?
      true
    end

    def after_save
      wizard.store["email_template"] = email_template
      wizard.store["funding_amount"] = funding_amount

      wizard.store["submitted"] = true
      wizard.session["clear_tra_login"] = true

      Services::HandleSubmissionForStore.new(store: wizard.store).call
    end

    def email_template
      @email_template ||= Services::EmailTemplate.call(data: wizard.store)
    end

    def funding_amount
      return nil unless wizard.query_store.targeted_delivery_funding_eligibility?

      @funding_amount ||= wizard.query_store.targeted_delivery_funding_eligibility? && wizard.query_store.tsf_primary_plus_eligibility? ? 800 : 200
    end
  end
end
