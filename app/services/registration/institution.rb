module Registration
  class Institution
    class << self
      def fetch(...) = new(...).fetch
    end

    def initialize(identifier:, works_in_childcare:, works_in_school:)
      @klass, @identifier = identifier&.split("-", 2)
      @works_in_childcare = works_in_childcare
      @works_in_school = works_in_school
    end

    def fetch
      case @klass
      when "PrivateChildcareProvider" then fetch_childcare_provider
      when "School" then fetch_school
      when "LocalAuthority" then fetch_local_authority
      end
    end

  private

    def fetch_childcare_provider
      return unless @works_in_childcare

      PrivateChildcareProvider.find_by(provider_urn: @identifier)
    end

    def fetch_school
      return unless @works_in_childcare || @works_in_school

      School.find_by(urn: @identifier)
    end

    def fetch_local_authority
      return unless @works_in_childcare || @works_in_school

      LocalAuthority.find_by(id: @identifier)
    end
  end
end
