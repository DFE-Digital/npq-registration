class User < ApplicationRecord
  INSIGNIFICANT_ATTRIBUTES = %w[
    raw_tra_provider_data
    feature_flag_id
    get_an_identity_id_synced_to_ecf
    updated_from_tra_at
    trn_lookup_status
    notify_user_for_future_reg
    email_updates_status
    email_updates_unsubscribe_key
  ].freeze

  devise :omniauthable, omniauth_providers: [:tra_openid_connect]

  has_paper_trail meta: { note: :version_note }, ignore: %i[raw_tra_provider_data updated_at feature_flag_id]

  has_many :applications, dependent: :destroy
  has_many :declarations, through: :applications
  has_many :participant_id_changes, -> { order("created_at desc") }
  has_many :declarations, through: :applications

  validates :full_name, presence: true

  validates :email,
            presence: true,
            uniqueness: true,
            notify_email: true

  validates :uid, uniqueness: { allow_blank: true }
  validates :ecf_id, uniqueness: { case_sensitive: false }

  after_commit :touch_significantly_updated_at

  scope :admins, -> { where(admin: true) }

  scope :with_get_an_identity_id, lambda {
    where.not(uid: nil)
         .where(provider: "tra_openid_connect")
  }

  EMAIL_UPDATES_STATES = %i[senco other_npq].freeze
  EMAIL_UPDATES_ALL_STATES = [:empty] + EMAIL_UPDATES_STATES

  enum :email_updates_status, EMAIL_UPDATES_ALL_STATES, suffix: true

  attr_accessor :version_note, :skip_touch_significantly_updated_at

  def latest_participant_outcome(lead_provider, course_identifier)
    declarations.eligible_for_outcomes(lead_provider, course_identifier)
      .first
      &.participant_outcomes
      &.latest
  end

  def self.find_by_get_an_identity_id(get_an_identity_id)
    with_get_an_identity_id.find_by(uid: get_an_identity_id)
  end

  def self.find_or_create_from_provider_data(provider_data, feature_flag_id:)
    Users::FindOrCreateFromProviderData.new(provider_data: provider_data, feature_flag_id: feature_flag_id).call
  end

  def get_an_identity_user
    return if get_an_identity_id.blank?

    External::GetAnIdentity::User.find(get_an_identity_id)
  end

  def get_an_identity_provider?
    provider == "tra_openid_connect"
  end

  def get_an_identity_id
    uid if get_an_identity_provider?
  end

  def actual_user?
    true
  end

  def null_user?
    false
  end

  def flipper_id
    "User;#{retrieve_or_persist_feature_flag_id}"
  end

  def retrieve_or_persist_feature_flag_id
    self.feature_flag_id ||= SecureRandom.uuid
    save!(validate: false) if feature_flag_id_changed?
    self.feature_flag_id
  end

  def update_email_updates_status(form)
    self.email_updates_status = form.email_updates_status
    self.email_updates_unsubscribe_key = SecureRandom.uuid if email_updates_unsubscribe_key.nil?
    save!
  end

  def unsubscribe_from_email_updates
    self.email_updates_status = "empty"
    self.email_updates_unsubscribe_key = nil
    save!
  end

  def archived?
    archived_email.present?
  end

  def set_closed_registration_feature_flag
    if Flipper.enabled?(Feature::CLOSED_REGISTRATION_ENABLED) && ClosedRegistrationUser.find_by(email:)
      Flipper.enable_actor(Feature::REGISTRATION_OPEN, self)
    end
  end

  def set_updated_from_tra_at
    return unless significant_change?

    self.updated_from_tra_at = Time.zone.now
  end

private

  def touch_significantly_updated_at
    return if skip_touch_significantly_updated_at

    changed_attributes = saved_changes.keys

    explicitly_updating_significantly_updated_at = changed_attributes.include?("significantly_updated_at")
    return if explicitly_updating_significantly_updated_at

    updated_at_touched = changed_attributes == %w[updated_at]

    update_column(:significantly_updated_at, updated_at) if updated_at_touched || significant_change?
  end

  def significant_change?
    (saved_changes.keys - (INSIGNIFICANT_ATTRIBUTES + %w[updated_at])).any? ||
      (changes.keys - (INSIGNIFICANT_ATTRIBUTES + %w[updated_at])).any?
  end
end
