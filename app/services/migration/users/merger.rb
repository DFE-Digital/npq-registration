module Migration
  module Users
    class Merger
      attr_reader :from_user, :to_user

      def initialize(from_user:, to_user:)
        @from_user = from_user
        @to_user = to_user
      end

      def merge!
        ApplicationRecord.transaction do
          from_user.applications.update!(user: to_user)
          from_user.update!(uid: nil)
        end
      end
    end
  end
end
