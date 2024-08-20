module Migration::Migrators
  class User < Base
    class << self
      def model_count
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
          .includes(:teacher_profile)
          .from("(#{users_with_npq_profiles.to_sql} UNION #{users_with_npq_applications.to_sql}) AS users")
      end
    end

    def call
      migrate(self.class.ecf_users) do |ecf_user|
        user = ::User.find_or_initialize_by(ecf_id: ecf_user.id)

        unique_trns = ecf_user.npq_applications.pluck(:teacher_reference_number).compact.uniq
        validate_multiple_trns!(unique_trns, user)

        user.update!(
          trn: ecf_user.teacher_profile&.trn ? ecf_user.teacher_profile.trn : unique_trns.last,
          full_name: ecf_user.full_name || user.full_name,
          email: ecf_user.email || user.email,
          uid: ecf_user.get_an_identity_id || user.uid,
        )
      end
    end

  private

    def validate_multiple_trns!(unique_trns, user)
      return unless unique_trns.size > 1

      user.errors.add(:base, "There are multiple different TRNs from NPQ applications")
      raise ActiveRecord::RecordInvalid, user
    end
  end
end
