module API
  module V3
    class StatementsSerializer < Blueprinter::Base
      association :statements, blueprint: StatementSerializer
    end
  end
end
