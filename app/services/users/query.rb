module Users
  class Query
    attr_reader :user

    def initialize(user:)
      @user = user
    end

    def user_with_matching_email
      User.where(email: user.email).where.not(id: user.id).first
    end
  end
end
