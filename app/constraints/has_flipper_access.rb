class HasFlipperAccess
  def self.matches?(request)
    current_user_id = request.session["admin_id"]

    current_user = Admin.find_by(id: current_user_id)

    current_user.present? && current_user.flipper_access?
  end
end
