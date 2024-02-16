module Ecf
  class EcfUserFinder
    attr_reader :user

    def initialize(user:)
      @user = user
    end

    def call
      External::EcfAPI::User.where(email: user.email).first
    end
  end
end
