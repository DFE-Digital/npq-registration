module External
  module EcfApi
    class User < Base
      has_many :npq_profiles
    end
  end
end
