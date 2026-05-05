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
      user_matched_using_trn = verified_trn_matching_users.first

      if user_matched_using_trn
        ApplicationRecord.transaction do
          user_matched_using_trn.update!(
            uid:,
            provider: Omniauth::Strategies::TeacherAuth::NAME,
            email:,
            full_name:,
            feature_flag_id:,
            previous_names:,
          )
          persist_token(user_matched_using_trn, provider_data)
        end

        merge_and_archive_other_users(user_matched_using_trn, verified_trn_matching_users[1..])
        return user_matched_using_trn
      end

      user_matched_using_uid = User.find_by(provider: Omniauth::Strategies::TeacherAuth::NAME, uid:)

      if user_matched_using_uid
        blank_clashing_email_user(except: user_matched_using_uid)
        ApplicationRecord.transaction do
          user_matched_using_uid.update!(
            email: email,
            trn:,
            trn_verified: true,
            trn_auto_verified: true,
            full_name:,
            feature_flag_id:,
            previous_names:,
          )
          persist_token(user_matched_using_uid, provider_data)
        end

        return user_matched_using_uid
      end

      if unverified_trn_matching_user
        ApplicationRecord.transaction do
          unverified_trn_matching_user.update!(
            uid:,
            provider: Omniauth::Strategies::TeacherAuth::NAME,
            trn_verified: true,
            trn_auto_verified: true,
            full_name:,
            feature_flag_id:,
            previous_names:,
          )
          persist_token(unverified_trn_matching_user, provider_data)
        end

        return unverified_trn_matching_user
      end

      blank_clashing_email_user

      user = nil
      ApplicationRecord.transaction do
        user = create_user_with_provider_data
        persist_token(user, provider_data)
      end

      user
    end

  private

    def persist_token(user, provider_data)
      refresh_token = provider_data.credentials&.refresh_token

      if user.trn.blank? && refresh_token.present?
        token_record = user.oauth_token || user.oauth_tokens.build(token_type: :refresh_token)
        token_record.update!(token: refresh_token, token_updated_at: Time.current)
        true
      elsif user.trn.present? && user.oauth_token.present?
        user.oauth_token.destroy!
        false
      else
        false
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
