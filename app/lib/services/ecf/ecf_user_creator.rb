module Services
  module Ecf
    class EcfUserCreator
      attr_reader :user

      def initialize(user:)
        @user = user
      end

      def call
        remote = EcfApi::User.new(email: user.email, full_name: user.full_name)
        remote.save
        user.update!(ecf_id: remote.id)
      end
    end
  end
end
