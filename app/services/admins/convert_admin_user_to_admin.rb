module Admins
  class ConvertAdminUserToAdmin
    def convert_admin_user_to_admin!(user)
      User.transaction do
        Rails.logger.debug("Converting user #{user.id} to an Admin")
        Admin.create! do |a|
          a.full_name = user.full_name
          a.email = user.email
          a.super_admin = user.super_admin
        end

        Rails.logger.debug("Converted user #{user.id} to an Admin, destroying User record")
        user.destroy!
      end
    end

    def convert_all_admin_users_to_admins!
      User.transaction do
        User.admins.each { |user| convert_admin_user_to_admin!(user) }
      end
    end
  end
end
