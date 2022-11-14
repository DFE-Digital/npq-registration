class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:tra_openid_connect]

  has_many :applications, dependent: :destroy

  validates :email, uniqueness: true

  def self.find_or_create_from_provider_data(provider_data, feature_flag_id:)
    user = find_or_create_from_tra_data_on_uid(provider_data, feature_flag_id:)

    return user if user.persisted?

    find_or_create_from_tra_data_on_unclaimed_email(provider_data, feature_flag_id:)
  end

  def self.find_or_create_from_tra_data_on_uid(provider_data, feature_flag_id:)
    user_from_provider_data = find_or_initialize_by(provider: provider_data.provider, uid: provider_data.uid)

    # Only set this if the user doesn't already have a feature flag profile
    user_from_provider_data.feature_flag_id ||= feature_flag_id

    trn = provider_data.info.trn

    user_from_provider_data.assign_attributes(
      email: provider_data.info.email,
      date_of_birth: provider_data.info.date_of_birth,
      trn:,
      trn_verified: trn.present?,
      full_name: provider_data.info.full_name,
      raw_tra_provider_data: provider_data,
    )

    user_from_provider_data.tap(&:save)
  end

  def self.find_or_create_from_tra_data_on_unclaimed_email(provider_data, feature_flag_id:)
    user_from_provider_data = find_or_initialize_by(provider: nil, uid: nil, email: provider_data.info.email)

    # Only set this if the user doesn't already have a feature flag profile
    user_from_provider_data.feature_flag_id ||= feature_flag_id

    trn = provider_data.info.trn

    user_from_provider_data.assign_attributes(
      provider: provider_data.provider,
      uid: provider_data.uid,
      date_of_birth: provider_data.info.date_of_birth,
      trn:,
      trn_verified: trn.present?,
      full_name: provider_data.info.full_name,
      raw_tra_provider_data: provider_data,
    )

    user_from_provider_data.tap(&:save)
  end

  def null_user?
    false
  end

  def in_get_an_identity_pilot?
    provider == "tra_openid_connect"
  end

  # Whether this user has admin access to the feature flagging interface
  def flipper_access?
    admin? && flipper_admin_access?
  end

  def get_an_identity_integration_active?
    Services::Feature.get_an_identity_integration_active_for?(self)
  end

  def flipper_id
    "User;#{retrieve_or_persist_feature_flag_id}"
  end

  def retrieve_or_persist_feature_flag_id
    self.feature_flag_id ||= SecureRandom.uuid
    save!(validate: false) if feature_flag_id_changed?
    self.feature_flag_id
  end
end
