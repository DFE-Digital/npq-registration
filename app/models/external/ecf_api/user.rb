module External
  module EcfAPI
    class User < Base
      has_many :npq_profiles
    end
  end
end
