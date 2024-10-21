module Migration
  module Users
    class Creator
      attr_reader :ecf_user, :ecf_user_email

      def initialize(ecf_user, ecf_user_email)
        @ecf_user = ecf_user
        @ecf_user_email = ecf_user_email
      end

      def find_or_initialize
        primary_user = find_primary_user

        # User doesn't exist at all
        if primary_user.nil? && user_by_ecf_user_email.nil?
          return ::User.new(ecf_id: ecf_user.id)
        end

        # Primary user found and `ecf_user_email` if blank or same as primary user
        if primary_user && (user_by_ecf_user_email.nil? || primary_user == user_by_ecf_user_email)
          return primary_user
        end

        ## No nil `user_by_ecf_user_email` from this point on

        if primary_user.nil? && user_by_ecf_user_email
          if ecf_user_by_ecf_user_email_user_ecf_id.nil? || email_user_ecf_id_links_to_orphan_ecf_user?
            user_by_ecf_user_email.ecf_id = ecf_user.id
            return user_by_ecf_user_email
          end

          raise_error("user not found with ecf_id or gai_id, user found with ecf_user_email. this user has a linked ecf_user which is not an orphan")
        end

        # primary user and email user found, are different
        if primary_user && user_by_ecf_user_email
          if ecf_user_by_ecf_user_email_user_ecf_id.nil? || email_user_ecf_id_links_to_orphan_ecf_user?
            # TODO: swap email to something else so primary_user.email can use it
            raise_error("User found with ecf_id or gai_id AND user found with ecf_user_email. ecf_user_email user is orphan. But we need to do some email swapping")
          end

          raise_error("User found with ecf_id or gai_id AND user found with ecf_user_email. ecf_user_email user is not orphan.")
        end
      end

    private

      def find_primary_user
        raise_on_multiple_ecf_users_with_same_ecf_id!

        if user_does_not_exist_on_npq?
          return nil
        end

        if both_ecf_ids_return_same_user? || only_ecf_id_return_user?
          return user_by_ecf_user_id
        end

        if both_ecf_ids_return_different_users?
          # ECF has primary user that has been deduped, second NPQ user links to orphaned or nil ecf_user
          # - ecf_user1.id => user1
          # - ecf_user1.get_an_identity_id => user2
          # - user2.ecf_id => ecf_user2 (orphan or nil)
          if gai_user_ecf_id_links_to_no_ecf_user? || gai_user_ecf_id_links_to_orphan_ecf_user?
            # We merge `user_by_ecf_user_gai_id` into `user_by_ecf_user_id`
            Users::Merger.new(from_user: user_by_ecf_user_gai_id, to_user: user_by_ecf_user_id).merge!
            return user_by_ecf_user_id
          end

          # ecf_user returns two NPQ users, the second NPQ user links to an ecf_user, which is not an orphan
          # - ecf_user1.id => user1
          # - ecf_user1.get_an_identity_id => user2
          # - user2.ecf_id => ecf_user2
          raise_error("ecf_user.id and ecf_user.get_an_identity_id both return NPQ User records, and the NPQ User link to non-orphan ECF users")
        end

        if only_ecf_gai_id_return_user?
          if gai_user_ecf_id_links_to_no_ecf_user? || gai_user_ecf_id_links_to_orphan_ecf_user?
            # We set `user.ecf_id` to `ecf_user.id`, return user
            user_by_ecf_user_gai_id.ecf_id = ecf_user.id
            return user_by_ecf_user_gai_id
          end

          # ecf_user only returns one NPQ user with get_an_identity_id,
          # this NPQ user links to an ecf_user with its ecf_id, which is not an orphan
          # - ecf_user1.id => nil
          # - ecf_user1.get_an_identity_id => user
          # - user.ecf_id => ecf_user2
          raise_error("User found with ecf_user.get_an_identity_id, but its user.ecf_id linked to another ecf_user that is not an orphan")
        end
      end

      def user_by_ecf_user_id
        # Find User with `ecf_user.id`
        @user_by_ecf_user_id ||= ::User.find_by(ecf_id: ecf_user.id)
      end

      def user_by_ecf_user_gai_id
        return if ecf_user.get_an_identity_id.blank?

        # Find User with `ecf_user.get_an_identity_id`
        @user_by_ecf_user_gai_id ||= ::User.find_by(uid: ecf_user.get_an_identity_id)
      end

      def user_by_ecf_user_email
        return if ecf_user_email.blank?

        # Find User with `ecf_user_email` (most recent npq_application identity email)
        @user_by_ecf_user_email ||= ::User.find_by(email: ecf_user_email)
      end

      def ecf_user_by_user_ecf_id
        return if user_by_ecf_user_gai_id&.ecf_id.blank?

        # Find ECF User with `user.ecf_id`, which was found with `ecf_user.get_an_identity_id`
        @ecf_user_by_user_ecf_id ||= Migration::Ecf::User.find_by(id: user_by_ecf_user_gai_id.ecf_id)
      end

      def ecf_user_by_ecf_user_email_user_ecf_id
        return if user_by_ecf_user_email.nil?

        # Find ECF User with `user_by_ecf_user_email.ecf_id`
        @ecf_user_by_ecf_user_email_user_ecf_id ||= Migration::Ecf::User.find_by(id: user_by_ecf_user_email.ecf_id)
      end

      def raise_error(msg)
        ecf_user.errors.add(:base, msg)
        raise ActiveRecord::RecordInvalid, ecf_user
      end

      def user_does_not_exist_on_npq?
        user_by_ecf_user_id.nil? && user_by_ecf_user_gai_id.nil?
      end

      def raise_on_multiple_ecf_users_with_same_ecf_id!
        # user.ecf_id is not validated as unique, check for duplicates
        return unless ::User.where(ecf_id: ecf_user.id).count > 1

        raise_error("ecf_user.id has multiple users in NPQ")
      end

      def only_ecf_id_return_user?
        # User found with `ecf_user.id`, but not `ecf_user.get_an_identity_id`
        user_by_ecf_user_id && user_by_ecf_user_gai_id.nil?
      end

      def both_ecf_ids_return_same_user?
        # Both id's return the same record, success
        user_by_ecf_user_id == user_by_ecf_user_gai_id
      end

      def both_ecf_ids_return_different_users?
        # We have User 2 records, but they are different
        user_by_ecf_user_id && user_by_ecf_user_gai_id &&
          user_by_ecf_user_id != user_by_ecf_user_gai_id
      end

      def only_ecf_gai_id_return_user?
        # Found User with `ecf_user.get_an_identity_id` only (not found with `ecf_user.id`)
        user_by_ecf_user_id.nil? && user_by_ecf_user_gai_id
      end

      def gai_user_ecf_id_links_to_no_ecf_user?
        ecf_user_by_user_ecf_id.nil?
      end

      def gai_user_ecf_id_links_to_orphan_ecf_user?
        orphaned_ecf_user?(ecf_user_by_user_ecf_id)
      end

      def email_user_ecf_id_links_to_orphan_ecf_user?
        orphaned_ecf_user?(ecf_user_by_ecf_user_email_user_ecf_id)
      end

      def orphaned_ecf_user?(u)
        # is it an orphan ecf user?
        u.npq_applications.empty? && u.npq_profiles.empty?
      end
    end
  end
end
