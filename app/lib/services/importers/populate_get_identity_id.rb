module Services
  module Importers
    class PopulateGetIdentityId
      def import(rows)
        rows.each do |row|
          user = Application.find(row.fetch(:id)).user
          user.update!(uid: row.fetch(:user_id))
          Rails.logger.info("User #{user.id} has been updated with get_identity_id #{row.fetch(:user_id)}")
        end
      end
    end
  end
end
