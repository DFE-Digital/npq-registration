module Migration::Migrators
  class User < Base
    def call
      migrate(ecf_users, :user) do |ecf_user|
        user = ::User.find_or_initialize_by(ecf_id: ecf_user.id)

        user.update!(
          trn: ecf_user.teacher_profile&.trn ? ecf_user.teacher_profile.trn : ecf_user.npq_applications.map(&:teacher_reference_number).compact.uniq.last,
          full_name: ecf_user.full_name || user.full_name,
          email: ecf_user.email || user.email,
          uid: ecf_user.get_an_identity_id || user.uid,
        )
      end
    end

  private

    def ecf_users
      @ecf_users ||= begin
        users_with_npq_profiles = Migration::Ecf::User
          .joins(teacher_profile: :npq_profiles)
          .all
          .where("participant_profiles.id is not NULL")

        users_with_npq_applications = Migration::Ecf::User
          .joins(participant_identities: :npq_applications)
          .all
          .where("npq_applications.id is not NULL")

        Migration::Ecf::User.from("(#{users_with_npq_profiles.to_sql} UNION #{users_with_npq_applications.to_sql}) AS users")
      end
    end
  end
end
