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
  end
end
