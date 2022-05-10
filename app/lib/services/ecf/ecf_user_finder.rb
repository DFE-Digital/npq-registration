module Services
  module Ecf
    class EcfUserFinder
      attr_reader :user

      def initialize(user:)
        @user = user
      end

      def call
        EcfApi::User.where(email: user.email).first
      end
    end
  end
end
