module Statements
  class Find
    def all
      Statement.eager_load(:cohort).all
    end
  end
end
