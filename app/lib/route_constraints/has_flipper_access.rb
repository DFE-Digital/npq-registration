module RouteConstraints
  class HasFlipperAccess
    def self.matches?(request)
      current_user_id = request.session["user_id"]

      current_user = User.find_by(id: current_user_id)

      current_user.present? && current_user.flipper_access?
    end
  end
end
