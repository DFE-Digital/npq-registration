module API
  module V3
    class CohortSerializer < Blueprinter::Base
      identifier :id

      field :start_year, name: :start_year
    end
  end
end
