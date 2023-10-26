module External
  module EcfApi
    module Npq
      class Base < External::EcfApi::Base
        self.site = "#{ENV['ECF_APP_BASE_URL']}/api/v1/npq"
      end
    end
  end
end
