module EcfApi
  module Npq
    class Base < ::EcfApi::Base
      self.site = "#{ENV['ECF_APP_BASE_URL']}/api/v1/npq"
    end
  end
end
