module Statements
  class Query
    def initialize(lead_provider:)
      @lead_provider = lead_provider
    end

    def statements
      Statement.where(lead_provider:)
    end

    def statement(id:)
      statements.find(id)
    end

  private

    attr_reader :lead_provider, :params
  end
end
