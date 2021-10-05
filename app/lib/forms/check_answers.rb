module Forms
  class CheckAnswers < Base
    include Helpers::Institution

    def previous_step
      :choose_your_provider
    end

    def next_step
      :confirmation
    end

    def after_save
      Services::HandleSubmissionForStore.new(store: wizard.store).call

      clear_answers_in_store
    end

  private

    def clear_answers_in_store
      wizard.store.clear
    end
  end
end
