module External
  module EcfApi
    class NpqProfile < Base
      def self.table_name
        "npq-profiles"
      end

      def self.type
        "npq_profiles"
      end

      belongs_to :user, shallow_path: true, param: :ecf_id
    end
  end
end
