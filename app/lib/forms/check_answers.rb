module Forms
  class CheckAnswers < Base
    include Helpers::Institution

    def previous_step
      :share_provider
    end

    def next_step
      :confirmation
    end

    def after_save
      Services::HandleSubmissionForStore.new(store: wizard.store).call
    end
  end
end
