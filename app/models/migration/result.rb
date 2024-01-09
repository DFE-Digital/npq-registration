module Migration
  class Result < ApplicationRecord
    self.table_name = "migration_results"
  end
end
