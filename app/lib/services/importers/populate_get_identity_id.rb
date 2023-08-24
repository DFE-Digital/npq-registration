module Services
  module Importers
    class PopulateGetIdentityId
      def import(rows)
        rows.each do |row|
          user = User.find(row.fetch(:user_id))
          user.update!(uid: row.fetch(:id))
          Rails.logger.info("User #{user.id} has been updated with get_identity_id #{row.fetch(:id)}")

          if user.synced_to_ecf?
            user.ecf_user.update!(get_identity_id: row.fetch(:id))
            Rails.logger.info("ECF user #{user.id} has been updated with get_identity_id #{row.fetch(:id)}")
          else
            Rails.logger.error("User #{user.id} get_identity_id has not been synced to ECF")
          end
        end
      end
    end
  end
end
