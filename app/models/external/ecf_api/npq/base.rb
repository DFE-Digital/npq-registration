module External
  module EcfAPI
    module Npq
      class Base < External::EcfAPI::Base
        self.site = "#{ENV['ECF_APP_BASE_URL']}/api/v1/npq"
      end
    end
  end
end
