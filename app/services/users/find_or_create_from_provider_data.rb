# frozen_string_literal: true

module Users
  class FindOrCreateFromProviderData
    def initialize(provider_data:, feature_flag_id:)
      @provider_data = provider_data
      @feature_flag_id = feature_flag_id
    end

    attr_reader :provider_data, :feature_flag_id

    def call
      user = User.find_by(provider: provider_data.provider, uid: provider_data.uid, archived_at: nil)

      if user
        check_and_archive_clashing_user(provider_data.info.email, user)
        user.assign_attributes(email: provider_data.info.email)
      else
        Rails.logger.info("[GAI] User not found using UID, UID=#{provider_data.uid}, using email to find user")
        check_if_supplied_uid_matches_archived_account # CPDNPQ-2647
        user = User.find_or_initialize_by(email: provider_data.info.email, archived_at: nil)
        user.assign_attributes(provider: provider_data.provider, uid: provider_data.uid)
      end

      assign_provider_data(user, provider_data)
      user.assign_attributes(feature_flag_id: feature_flag_id)

      user.tap(&:save)
    end

  private

    def check_if_supplied_uid_matches_archived_account
      user_with_clashing_uid = User.find_by(provider: provider_data.provider, uid: provider_data.uid)
      if user_with_clashing_uid&.archived?
        Rails.logger.info("[GAI] User found using email has a clashing archived user with UID=#{provider_data.uid}, ID=#{user_with_clashing_uid.id}, setting UID to nil")
        Users::Archiver.new(user: user_with_clashing_uid).set_uid_to_nil!
      end
    end

    def check_and_archive_clashing_user(email, user_to_keep)
      user_with_clashing_email = User.where.not(id: user_to_keep.id).find_by(email: email)
      if user_with_clashing_email
        Rails.logger.info("[GAI] User found using UID has a clashing user with same email, UID=#{provider_data.uid}, ID=#{user_with_clashing_email.id}, merging and archiving clashing user")
        Users::MergeAndArchive.new(user_to_merge: user_with_clashing_email, user_to_keep:).call(dry_run: false)
      end
    end

    def assign_provider_data(user, provider_data)
      extra_info = provider_data.extra&.raw_info

      user.raw_tra_provider_data = provider_data
      user.updated_from_tra_at = Time.zone.now
      user.full_name = extra_info&.preferred_name.presence || provider_data.info.name

      if extra_info&.birthdate.present?
        user.date_of_birth = Date.parse(extra_info.birthdate, "%Y-%m-%d")
      end

      # The user's TRN should remain unchanged if the TRA returns an empty TRN
      if extra_info&.trn.present?
        user.trn = extra_info.trn
        user.trn_verified = true
        user.trn_lookup_status = extra_info.trn_lookup_status
      end
    end
  end
end
