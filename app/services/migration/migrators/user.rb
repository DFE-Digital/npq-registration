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

      def records_per_worker
        (super / 2.0).ceil
      end
    end

    def call
      migrate(self.class.ecf_users) do |ecf_user|
        user = ::Migration::Users::Creator.new(ecf_user).find_or_initialize

        application_trns = validated_application_trns(ecf_user)
        raise_if_multiple_application_trns_and_no_teacher_profile_trn!(application_trns, ecf_user)
        ecf_trn = ecf_user.teacher_profile&.trn || application_trns.last

        npq_application = most_recent_created_npq_application(ecf_user)
        email = npq_application&.participant_identity&.email

        user.update!(
          trn: ecf_trn || user.trn,
          full_name: ecf_user.full_name || user.full_name,
          email:,
          uid: ecf_user.get_an_identity_id || user.uid,
          date_of_birth: npq_application.date_of_birth || user.date_of_birth,
          national_insurance_number: npq_application.nino || user.national_insurance_number,
          active_alert: npq_application.active_alert || user.active_alert,
          trn_verified: ecf_trn.present? || user&.trn_verified,
        )
      end
    end

  private

    def validated_application_trns(ecf_user)
      ecf_user.npq_applications
        .where(teacher_reference_number_verified: true)
        .pluck(:teacher_reference_number)
        .compact
        .uniq
    end

    def most_recent_created_npq_application(ecf_user)
      profile_apps = Migration::Ecf::NpqApplication.where(id: ecf_user.npq_profiles.select(:id))
      user_apps = ecf_user.npq_applications

      Migration::Ecf::NpqApplication
        .from("(#{profile_apps.to_sql} UNION #{user_apps.to_sql}) AS npq_applications")
        .order(created_at: :desc)
        .first
    end

    def raise_if_multiple_application_trns_and_no_teacher_profile_trn!(application_trns, user)
      return if application_trns.size < 2 || user.teacher_profile&.trn

      user.errors.add(:base, "There are multiple different TRNs from NPQ applications")
      raise ActiveRecord::RecordInvalid, user
    end
  end
end
