module Statements
  class Query
    def initialize
      @scope = Statement.all
    end

    def belonging_to(lead_provider:)
      @scope = @scope
                 .includes(:cohort)
                 .where(lead_provider:)

      self
    end

    def by_cohorts(*start_years)
      if start_years.any?
        @scope = @scope.where(cohort: { start_year: start_years })
      end

      self
    end

    def since(date)
      if date.present?
        @scope = @scope.where(updated_at: date..)
      end

      self
    end

    def statements
      @scope
    end

    def statement(id:)
      statements.find(id)
    end
  end
end
