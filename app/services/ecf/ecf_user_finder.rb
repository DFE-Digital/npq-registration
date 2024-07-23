module Ecf
  class EcfUserFinder
    attr_reader :user

    def initialize(user:)
      @user = user
    end

    def call
      return if Rails.application.config.npq_separation[:ecf_api_disabled]

      External::EcfAPI::User.where(email: user.email).first
    end
  end
end
