module Migration
  class UserMigrator
    attr_reader :ecf_user

    def initialize(ecf_user)
      @ecf_user = ecf_user
    end

    def find_initialize_or_merge_user
      if user_does_not_exist?
        return ::User.new(ecf_id: ecf_user.id)
      end

      validate_multiple_users_with_same_ecf_id

      if both_ids_return_same_user? || only_ecf_id_return_user?
        return ecf_user_id_user
      end

      if both_ids_return_different_users?
        # Scenario 1 on JIRA
        # - ecf_user1 => user1
        # - ecf_user1 => user2
        # - user2 => ecf_user2 (orphan or nil)
        if gai_user_ecf_id_links_to_nothing? || gai_user_ecf_id_links_to_orphan_ecf_user?
          # We merge `ecf_user_gai_id_user` into `ecf_user_id_user`
          UserMerger.new(from_user: ecf_user_gai_id_user, to_user: ecf_user_id_user).merge!
          return ecf_user_id_user
        end

        # Scenario 3 and Scenario 2 (when running on ecf_user with 8910)
        # - ecf_user1 => user1
        # - ecf_user1 => user2
        # - user2 => ecf_user2
        raise_error("ecf_user.id and ecf_user.get_an_identity_id both return NPQ User records, and the NPQ User link to non-orphan ECF users")
      end

      if only_gai_id_return_user?
        if gai_user_ecf_id_links_to_nothing? || gai_user_ecf_id_links_to_orphan_ecf_user?
          # We set `user.ecf_id` to `ecf_user.id`, return user
          ecf_user_gai_id_user.ecf_id = ecf_user.id
          return ecf_user_gai_id_user
        end

        # Scenario 2 on JIRA (when running on ecf_user with 123)
        raise_error("User found with ecf_user.get_an_identity_id, but its user.ecf_id linked to another ecf_user that is not an orphan")
      end
    end

  private

    def ecf_user_id_user
      # Find User with `ecf_user.id`
      @ecf_user_id_user ||= ::User.find_by(ecf_id: ecf_user.id)
    end

    def ecf_user_gai_id_user
      return if ecf_user.get_an_identity_id.blank?

      # Find User with `ecf_user.get_an_identity_id`
      @ecf_user_gai_id_user ||= ::User.find_by(uid: ecf_user.get_an_identity_id)
    end

    def user_gai_id_ecf_user
      return if ecf_user_gai_id_user&.ecf_id.blank?

      # Find ECF User with `user.ecf_id`, which was found with `ecf_user.get_an_identity_id`
      @user_gai_id_ecf_user ||= Migration::Ecf::User.find_by(id: ecf_user_gai_id_user.ecf_id)
    end

    def raise_error(msg)
      ecf_user.errors.add(:base, msg)
      raise ActiveRecord::RecordInvalid, ecf_user
    end

    def user_does_not_exist?
      ecf_user_id_user.nil? && ecf_user_gai_id_user.nil?
    end

    def validate_multiple_users_with_same_ecf_id
      # user.ecf_id is not validated as unique, check for duplicates
      return unless ::User.where(ecf_id: ecf_user.id).count > 1

      raise_error("ecf_user.id has multiple users in NPQ")
    end

    def only_ecf_id_return_user?
      # User found with `ecf_user.id`, but not `ecf_user.get_an_identity_id`
      ecf_user_id_user && ecf_user_gai_id_user.nil?
    end

    def both_ids_return_same_user?
      # Both id's return the same record, success
      ecf_user_id_user == ecf_user_gai_id_user
    end

    def both_ids_return_different_users?
      # We have User 2 records, but they are different
      ecf_user_id_user && ecf_user_gai_id_user &&
        ecf_user_id_user != ecf_user_gai_id_user
    end

    def only_gai_id_return_user?
      # Found User with `ecf_user.get_an_identity_id` only (not found with `ecf_user.id`)
      ecf_user_id_user.nil? && ecf_user_gai_id_user
    end

    def gai_user_ecf_id_links_to_nothing?
      user_gai_id_ecf_user.nil?
    end

    def gai_user_ecf_id_links_to_orphan_ecf_user?
      # is it an orphan ecf user?
      user_gai_id_ecf_user.npq_applications.empty? && user_gai_id_ecf_user.npq_profiles.empty?
    end
  end
end
