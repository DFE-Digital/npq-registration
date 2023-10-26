module External
  module EcfApi
    class NpqFunding < Base
      self.parser = RawParser

      def self.table_name
        "npq-funding"
      end
    end
  end
end
