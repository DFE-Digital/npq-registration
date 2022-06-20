module Forms
  module Helpers
    module Institution
    private

      def institution(source: wizard.store["institution_identifier"])
        return @institution if @institution
        return nil if source.nil?

        klass, identifier = source.split("-")

        @institution ||= case klass
                         when "PrivateChildcareProvider"
                           load_private_childcare_provider_institution(identifier)
                         when "School"
                           load_school_institution(identifier)
                         when "LocalAuthority"
                           load_local_authority_institution(identifier)
                         end
      end

      def load_private_childcare_provider_institution(identifier)
        return unless query_store.works_in_private_childcare_provider?

        PrivateChildcareProvider.find_by(provider_urn: identifier)
      end

      def load_school_institution(identifier)
        return unless query_store.works_in_public_childcare_provider? || query_store.works_in_school?

        School.find_by(urn: identifier)
      end

      def load_local_authority_institution(identifier)
        return unless query_store.works_in_public_childcare_provider? || query_store.works_in_school?

        LocalAuthority.find_by(id: identifier)
      end
    end
  end
end
