# frozen_string_literal: true

module Users
  class FindOrCreateFromTeacherAuth
    def initialize(provider_data:, feature_flag_id:)
      @provider_data = provider_data
      @access_token = provider_data.credentials.token
      @uid = provider_data.uid
      @trn = provider_data.extra.raw_info.trn
      @email = provider_data.info.email
      @feature_flag_id = feature_flag_id
      @full_name = provider_data.extra.raw_info.verified_name.join(" ")
      @date_of_birth = Date.parse(provider_data.extra.raw_info.verified_date_of_birth, "%Y-%m-%d")
    end

    attr_reader :provider_data, :access_token, :uid, :trn, :email, :full_name, :date_of_birth, :feature_flag_id

    def call
      user = update_verified_trn_match ||
        update_uid_match ||
        update_unverified_trn_match ||
        create_new_user

      Users::SetRefreshToken.call(user:, refresh_token: provider_data.credentials&.refresh_token)
      user
    end

  private

    def update_verified_trn_match
      user = verified_trn_matching_users.first
      return unless user

      ApplicationRecord.transaction do
        user.update!(
          uid:,
          provider: Omniauth::Strategies::TeacherAuth::NAME,
          email:,
          full_name:,
          feature_flag_id:,
          previous_names:,
        )
      end

      merge_and_archive_other_users(user, verified_trn_matching_users[1..])
      user
    end

    def update_uid_match
      user = User.find_by(provider: Omniauth::Strategies::TeacherAuth::NAME, uid:)
      return unless user

      blank_clashing_email_user(except: user)
      ApplicationRecord.transaction do
        user.update!(
          email:,
          trn:,
          trn_verified: true,
          trn_auto_verified: true,
          full_name:,
          feature_flag_id:,
          previous_names:,
        )
      end

      user
    end

    def update_unverified_trn_match
      user = unverified_trn_matching_user
      return unless user

      ApplicationRecord.transaction do
        user.update!(
          uid:,
          provider: Omniauth::Strategies::TeacherAuth::NAME,
          trn_verified: true,
          trn_auto_verified: true,
          full_name:,
          feature_flag_id:,
          previous_names:,
        )
      end

      user
    end

    def create_new_user
      blank_clashing_email_user

      ApplicationRecord.transaction do
        create_user_with_provider_data
      end
    end

    def verified_trn_matching_users
      @verified_trn_matching_users ||=
        User.where(trn:, trn_verified: true, archived_at: nil).order(updated_at: :desc).all.to_a
    end

    def unverified_trn_matching_user
      @unverified_trn_matching_user ||=
        User.find_by(provider: Omniauth::Strategies::TraOpenidConnect::NAME, trn:, trn_verified: false, email:, archived_at: nil)
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
        email:,
        trn:,
        trn_verified: true,
        trn_auto_verified: true,
        full_name:,
        date_of_birth:,
        feature_flag_id:,
        previous_names:,
      )
    end
  end
end
