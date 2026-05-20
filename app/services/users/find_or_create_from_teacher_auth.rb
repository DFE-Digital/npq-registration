# frozen_string_literal: true

module Users
  class FindOrCreateFromTeacherAuth
    def initialize(provider_data:, feature_flag_id:)
      @access_token = provider_data.credentials.token
      @uid = provider_data.uid
      @trn = provider_data.extra.raw_info.trn
      @email = provider_data.info.email
      @feature_flag_id = feature_flag_id
      @full_name = provider_data.extra.raw_info.verified_name.join(" ")
      @date_of_birth = Date.parse(provider_data.extra.raw_info.verified_date_of_birth, "%Y-%m-%d")
    end

    attr_reader :access_token, :uid, :trn, :email, :full_name, :date_of_birth, :feature_flag_id

    def call
      user_matched_using_trn = verified_trn_matching_users.first

      if user_matched_using_trn
        user_matched_using_trn.update!(
          always_updated_attributes.merge(
            email:,
            uid:,
            provider: Omniauth::Strategies::TeacherAuth::NAME,
          ),
        )
        merge_and_archive_other_users(user_matched_using_trn, verified_trn_matching_users[1..])
        return user_matched_using_trn
      end

      user_matched_using_uid = User.find_by(provider: Omniauth::Strategies::TeacherAuth::NAME, uid:)

      if user_matched_using_uid
        blank_clashing_email_user(except: user_matched_using_uid)
        user_matched_using_uid.update!(
          always_updated_attributes.merge(
            email:,
            trn:,
            trn_verified: true,
          ),
        )
        return user_matched_using_uid
      end

      if unverified_trn_matching_user
        unverified_trn_matching_user.update!(
          always_updated_attributes.merge(
            uid:,
            provider: Omniauth::Strategies::TeacherAuth::NAME,
            trn_verified: true,
          ),
        )
        return unverified_trn_matching_user
      end

      blank_clashing_email_user
      create_user_with_provider_data
    end

  private

    def verified_trn_matching_users
      @verified_trn_matching_users ||=
        User.where(trn:, trn_verified: true, archived_at: nil).order(updated_at: :desc).all.to_a
    end

    def unverified_trn_matching_user
      @unverified_trn_matching_user ||=
        User.find_by(provider: Omniauth::Strategies::TraOpenidConnect::NAME, trn:, trn_verified: false, email:, archived_at: nil)
    end

    def always_updated_attributes
      {
        date_of_birth:,
        feature_flag_id:,
        full_name:,
        previous_names:,
        trn_auto_verified: true,
      }
    end

    def blank_clashing_email_user(except: nil)
      scope = User.where(email:).where(archived_at: nil)
      scope = scope.where.not(id: except.id) if except
      clashing = scope.first
      return unless clashing

      Users::Archiver.new(user: clashing).archive!(blank_email: true)
    end

    def merge_and_archive_other_users(user_to_keep, users_to_merge)
      users_to_merge.each do |user_to_merge|
        Users::MergeAndArchive.new(user_to_merge:, user_to_keep:).call(dry_run: false)
      end
    end

    def previous_names
      return [] if @trn.blank?

      @previous_names ||= TeachingRecordSystem::FetchPerson.fetch(access_token:).previous_names
    end

    def create_user_with_provider_data
      User.create!(
        uid:,
        provider: Omniauth::Strategies::TeacherAuth::NAME,
        date_of_birth:,
        email:,
        feature_flag_id:,
        full_name:,
        previous_names:,
        trn:,
        trn_auto_verified: true,
        trn_verified: true,
      )
    end
  end
end
