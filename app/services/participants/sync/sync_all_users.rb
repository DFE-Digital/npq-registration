module Participants
  module Sync
    class SyncAllUsers
      def sync_all_users!
        User.find_each { |user| SyncFromUser.new(user).sync! }
      end
    end
  end
end
