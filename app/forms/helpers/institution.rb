module Helpers
  module Institution
  private

    def institution(source: wizard.store["institution_identifier"], application: nil)
      @institution ||= begin
        application ||= query_store
        ::Registration::Institution.fetch(
          identifier: source,
          works_in_school: application.works_in_school?,
          works_in_childcare: application.works_in_childcare?,
        )
      end
    end
  end
end
