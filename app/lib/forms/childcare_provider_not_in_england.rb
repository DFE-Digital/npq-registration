module Forms
  class ChildcareProviderNotInEngland < Base
    def previous_step
      :choose_childcare_provider
    end
  end
end
