module EcfApi
  module Npq
    class PreviousFunding < Base
      self.parser = RawParser

      def self.table_name
        "previous_funding"
      end
    end
  end
end
