class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:tra_openid_connect]

  has_many :applications, dependent: :destroy

  validates :email, uniqueness: true

  # TODO: What do we do if someone has already registered their email but not via TRA?
  # Should it hook up to the existing record or deprecate the old one?
  def self.from_provider_data(provider_data)
    user = find_or_create_from_tra_data_on_uid(provider_data)

    return user if user.persisted?

    find_or_create_from_tra_data_on_unclaimed_email(provider_data)
  end

  def self.find_or_create_from_tra_data_on_uid(provider_data)
    user_from_provider_data = find_or_initialize_by(provider: provider_data.provider, uid: provider_data.uid)

    user_from_provider_data.assign_attributes(
      email: provider_data.info.email,
      full_name: provider_data.info.name,
      raw_tra_provider_data: provider_data,
    )

    user_from_provider_data.tap(&:save)
  end

  def self.find_or_create_from_tra_data_on_unclaimed_email(provider_data)
    user_from_provider_data = find_or_initialize_by(provider: nil, uid: nil, email: provider_data.info.email)

    user_from_provider_data.assign_attributes(
      provider: provider_data.provider,
      uid: provider_data.uid,
      full_name: provider_data.info.name,
      raw_tra_provider_data: provider_data,
    )

    user_from_provider_data.tap(&:save)
  end

  def null_user?
    false
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
