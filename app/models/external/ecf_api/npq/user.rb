module External
  module EcfAPI
    module Npq
      class User < Base
        has_many :npq_profiles
      end
    end
  end
end
