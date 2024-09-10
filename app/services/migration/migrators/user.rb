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
        user = ::User.find_or_initialize_by(ecf_id: ecf_user.id)

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
          date_of_birth: npq_application.date_of_birth || user.date_of_birth,
          national_insurance_number: npq_application.nino || user.national_insurance_number,
          active_alert: npq_application.active_alert,
          trn_verified: npq_application.teacher_reference_number_verified,
        )
      end
    end

  private

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
      ecf_user.npq_applications.order(updated_at: :desc).first
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
