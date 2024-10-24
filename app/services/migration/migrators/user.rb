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
        npq_application = most_recent_created_npq_application(ecf_user)
        email = npq_application&.participant_identity&.email&.downcase

        user = ::Migration::Users::Creator.new(ecf_user, email).find_or_initialize

        application_trns_by_verified = application_trns_by_verified(ecf_user)

        raise_if_multiple_verified_application_trns_and_no_teacher_profile_trn!(application_trns_by_verified[true], ecf_user)
        ecf_verified_trn = ecf_user.teacher_profile&.trn || application_trns_by_verified[true]&.first
        ecf_unverified_trn = application_trns_by_verified[false]&.first

        attrs = {
          trn: ecf_verified_trn || ecf_unverified_trn || user.trn,
          full_name: ecf_user.full_name || user.full_name,
          email:,
          uid: ecf_user.get_an_identity_id || user.uid,
          date_of_birth: npq_application.date_of_birth || user.date_of_birth,
          national_insurance_number: npq_application.nino || user.national_insurance_number,
          active_alert: npq_application.active_alert || user.active_alert,
          trn_verified: ecf_verified_trn.present? || (ecf_unverified_trn.blank? && user&.trn_verified),
          created_at: ecf_user.created_at,
          updated_at: ecf_user.updated_at,
          version_note: "Changes migrated from ECF to NPQ",
        }

        if changed_ecf_user_attrs?(attrs, ecf_user)
          attrs[:updated_at] = Time.zone.now
        end

        user.update!(attrs)
      end
    end

  private

    def application_trns_by_verified(ecf_user)
      ecf_user.npq_applications
        .order(created_at: :desc)
        .where.not(teacher_reference_number: nil)
        .pluck(:teacher_reference_number_verified, :teacher_reference_number)
        .uniq
        .each_with_object({}) do |(verified, trn), hash|
          hash[verified] ||= []
          hash[verified] << trn
        end
    end

    def most_recent_created_npq_application(ecf_user)
      profile_apps = Migration::Ecf::NpqApplication.where(id: ecf_user.npq_profiles.select(:id))
      user_apps = ecf_user.npq_applications

      Migration::Ecf::NpqApplication
        .from("(#{profile_apps.to_sql} UNION #{user_apps.to_sql}) AS npq_applications")
        .order(created_at: :desc)
        .first
    end

    def raise_if_multiple_verified_application_trns_and_no_teacher_profile_trn!(verified_application_trns, user)
      return if !verified_application_trns || verified_application_trns.size < 2 || user.teacher_profile&.trn

      user.errors.add(:base, "There are multiple different, verified TRNs from NPQ applications")
      raise ActiveRecord::RecordInvalid, user
    end

    def changed_ecf_user_attrs?(attrs, ecf_user)
      attrs[:trn] != ecf_user.teacher_profile&.trn ||
        attrs[:email] != ecf_user.email
    end
  end
end
