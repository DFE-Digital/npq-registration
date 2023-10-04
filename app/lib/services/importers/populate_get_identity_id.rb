module Services
  module Importers
    class PopulateGetIdentityId
      def import(rows)
        rows.each do |row|
          user = Application.find_by!(ecf_id: row.fetch(:id)).user
          if user.uid.blank?
            user.update!(
              provider: "tra_openid_connect",
              uid: row.fetch(:user_id),
            )
            Rails.logger.info("User #{user.id} has been updated with get_identity_id #{row.fetch(:user_id)}")
          else
            Rails.logger.info("User #{user.id} already has an uid.")
            if user.uid != row.fetch(:user_id)
              Rails.logger.error("User #{user.id} already has a different uid? #{user.uid} vs #{row.fetch(:user_id)}")
            end
          end
        end
      end
    end
  end
end
