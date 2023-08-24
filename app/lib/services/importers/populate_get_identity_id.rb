module Services
  module Importers
    class PopulateGetIdentityId
      def import(rows)
        rows.each do |row|
          user = User.find(row.fetch(:user_id))
          user.update!(uid: row.fetch(:id))
        end
      end
    end
  end
end
