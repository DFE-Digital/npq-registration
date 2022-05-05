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
                           PrivateChildcareProvider.find_by(provider_urn: identifier)
                         when "School"
                           School.find_by(urn: identifier)
                         when "LocalAuthority"
                           LocalAuthority.find_by(id: identifier)
                         end
      end
    end
  end
end
