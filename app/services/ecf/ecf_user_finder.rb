module Ecf
  class EcfUserFinder
    prepend Base

    attr_reader :user

    def initialize(user:)
      @user = user
    end

    def call
      External::EcfAPI::User.where(email: user.email).first
    end
  end
end
