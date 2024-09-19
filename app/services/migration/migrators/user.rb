module Migration::Migrators
  class User < Base
    class << self
      def record_count
        ecf_users.count
      end

      def model
        :user
      end

      def ecf_users
        users_with_npq_profiles = Migration::Ecf::User
          .joins(teacher_profile: :npq_profiles)
          .all
          .where("participant_profiles.id is not NULL")

        users_with_npq_applications = Migration::Ecf::User
          .joins(participant_identities: :npq_applications)
          .all
          .where("npq_applications.id is not NULL")

        Migration::Ecf::User
          .includes(:teacher_profile, :npq_profiles)
          .from("(#{users_with_npq_profiles.to_sql} UNION #{users_with_npq_applications.to_sql}) AS users")
      end
    end

    def call
      migrate(self.class.ecf_users) do |ecf_user|
        user = find_or_initialize_user(ecf_user)

        trns = unique_validated_trns(ecf_user)
        validate_multiple_trns!(trns, user)

        emails = unique_emails(ecf_user)
        validate_multiple_emails!(emails, user)
        validate_existing_email_match!(emails.first, user)

        npq_application = most_recent_updated_npq_application(ecf_user)

        user.update!(
          trn: ecf_user.teacher_profile&.trn ? ecf_user.teacher_profile.trn : trns.last,
          full_name: ecf_user.full_name || user.full_name,
          email: emails.first || user.email,
          uid: ecf_user.get_an_identity_id || user.uid,
          date_of_birth: npq_application&.date_of_birth || user.date_of_birth,
          national_insurance_number: npq_application&.nino || user.national_insurance_number,
          active_alert: npq_application&.active_alert || user.active_alert,
          trn_verified: npq_application&.teacher_reference_number_verified || user.trn_verified,
        )
      end
    end

  private

    def find_or_initialize_user(ecf_user)
      # Find Users with `ecf_user.id`
      users_with_ecf_id = ::User.where(ecf_id: ecf_user.id)

      # Find User with `ecf_user.get_an_identity_id`
      if ecf_user.get_an_identity_id.present?
        user_with_gai_id = ::User.find_by(uid: ecf_user.get_an_identity_id)
      end

      # user.ecf_id is not validated as unique, check for duplicates
      if users_with_ecf_id && users_with_ecf_id.size > 1
        ecf_user.errors.add(:base, "ecf_user.id has multiple users in NPQ")
        raise ActiveRecord::RecordInvalid, ecf_user
      end

      # User with `ecf_user.id`
      user_with_ecf_id = users_with_ecf_id.first

      # User does not exist, initialize new user
      if user_with_ecf_id.nil? && user_with_gai_id.nil?
        return ::User.new(ecf_id: ecf_user.id)
      end

      # Both id's return the same record, success
      if user_with_ecf_id == user_with_gai_id
        return user_with_ecf_id
      end

      # User found with `ecf_user.id`, but not `ecf_user.get_an_identity_id`
      if user_with_ecf_id && user_with_gai_id.nil?
        return user_with_ecf_id
      end

      # We have User 2 records, but they are different
      if user_with_ecf_id && user_with_gai_id && user_with_ecf_id != user_with_gai_id
        ecf_user.errors.add(:base, "ecf_user.id and ecf_user.get_an_identity_id both return User records, but they are different")
        raise ActiveRecord::RecordInvalid, ecf_user
      end

      # Found User with `ecf_user.get_an_identity_id` only (not found with `ecf_user.id`)
      if user_with_ecf_id.nil? && user_with_gai_id
        # Can we find a `ecf_user` with `user.ecf_id`?
        ecf_user_from_gai_user_ecf_id = Migration::Ecf::User.find_by(id: user_with_gai_id.ecf_id)

        # Not found
        if ecf_user_from_gai_user_ecf_id.nil?
          # We set `user.ecf_id` to `ecf_user.id`, return user
          user_with_gai_id.ecf_id = ecf_user.id
          return user_with_gai_id
        end

        # Found, is it an orphan user?
        if ecf_user_from_gai_user_ecf_id.npq_applications.empty? && ecf_user_from_gai_user_ecf_id.npq_profiles.empty?
          # Orphaned ecf_user, we set `user.ecf_id` to `ecf_user.id`, return user
          user_with_gai_id.ecf_id = ecf_user.id
          return user_with_gai_id
        end

        ecf_user.errors.add(:base, "User found with ecf_user.get_an_identity_id, but its user.ecf_id linked to another ecf_user that is not an orphan")
        raise ActiveRecord::RecordInvalid, ecf_user
      end
    end

    def unique_validated_trns(ecf_user)
      ecf_user.npq_applications
        .where(teacher_reference_number_verified: true)
        .pluck(:teacher_reference_number)
        .compact
        .uniq
    end

    def unique_emails(ecf_user)
      emails = ecf_user.npq_profiles.map { |pp| pp.participant_identity.email }
      emails += ecf_user.npq_applications.map { |app| app.participant_identity.email }
      emails.map { |email| email.to_s.downcase.strip }.compact.uniq
    end

    def most_recent_updated_npq_application(ecf_user)
      profile_apps = Migration::Ecf::NpqApplication.where(id: ecf_user.npq_profiles.select(:id))
      user_apps = ecf_user.npq_applications

      Migration::Ecf::NpqApplication
        .from("(#{profile_apps.to_sql} UNION #{user_apps.to_sql}) AS npq_applications")
        .order(updated_at: :desc)
        .first
    end

    def validate_multiple_trns!(trns, user)
      return unless trns.size > 1

      user.errors.add(:base, "There are multiple different TRNs from NPQ applications")
      raise ActiveRecord::RecordInvalid, user
    end

    def validate_multiple_emails!(unique_emails, user)
      return unless unique_emails.size > 1

      user.errors.add(:base, "There are multiple different emails from user identities in NPQ applications")
      raise ActiveRecord::RecordInvalid, user
    end

    def validate_existing_email_match!(ecf_email, user)
      return if user.email.blank?
      return if ecf_email == user.email

      user.errors.add(:base, "Participant identity email from ECF does not match existing user email in NPQ")
      raise ActiveRecord::RecordInvalid, user
    end
  end
end
