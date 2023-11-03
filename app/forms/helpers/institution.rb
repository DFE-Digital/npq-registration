module Helpers
  module Institution
  private

    def institution(source: wizard.store["institution_identifier"], application: nil)
      return @institution if @institution
      return nil if source.nil?

      klass, identifier = source.split("-")
      application = application.nil? ? query_store : application
      @institution ||= case klass
                       when "PrivateChildcareProvider"
                         load_private_childcare_provider_institution(identifier, application)
                       when "School"
                         load_school_institution(identifier, application)
                       when "LocalAuthority"
                         load_local_authority_institution(identifier, application)
                       end
    end

    def load_private_childcare_provider_institution(identifier, application)
      return unless application.works_in_childcare?

      PrivateChildcareProvider.find_by(provider_urn: identifier)
    end

    def load_school_institution(identifier, application)
      return unless application.works_in_childcare? || application.works_in_school?

      School.find_by(urn: identifier)
    end

    def load_local_authority_institution(identifier, application)
      return unless application.works_in_childcare? || application.works_in_school?

      LocalAuthority.find_by(id: identifier)
    end
  end
end
