class User < ApplicationRecord
  has_many :applications, dependent: :destroy

  validates :email, uniqueness: true

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
