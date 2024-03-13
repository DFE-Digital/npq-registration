module Statements
  class Find
    def all
      Statement.eager_load(:cohort).all
    end

    def paid
      Statement.eager_load(:cohort).paid
    end

    def unpaid
      Statement.eager_load(:cohort).unpaid
    end

    def belonging_to(lead_provider:)
      Statement.eager_load(:lead_provider).where(lead_provider:)
    end

    def find_by_id(id)
      Statement.find(id)
    end
  end
end
