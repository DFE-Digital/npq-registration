module Statements
  class StatementsQuery
    def initialize(lead_provider:, params:)
      @lead_provider = lead_provider
      @cohort = params[:cohort]
      @update_since = params[:updated_since]
    end

    def statements
      Statement.all
    end

    def statement; end

  private

    attr_reader \
      :lead_provider,
      :cohort,
      :update_since
  end
end
