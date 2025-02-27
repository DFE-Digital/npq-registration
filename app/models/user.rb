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

  has_paper_trail meta: { note: :version_note }, ignore: [:raw_tra_provider_data]

  has_many :applications, dependent: :destroy
  has_many :declarations, through: :applications
  has_many :ecf_sync_request_logs, as: :syncable, dependent: :destroy
  has_many :participant_id_changes, -> { order("created_at desc") }
  has_many :declarations, through: :applications

  validates :full_name, presence: { message: "Enter a full name" }

  validates :email,
            presence: { message: "Enter an email address" },
            uniqueness: { message: "Email address must be unique" },
            notify_email: true

  validates :uid, uniqueness: { allow_blank: true }
  validates :ecf_id, uniqueness: { case_sensitive: false }

  after_commit :touch_significantly_updated_at

  scope :admins, -> { where(admin: true) }
  scope :unsynced, -> { where(ecf_id: nil) }
  scope :synced_to_ecf, -> { where.not(ecf_id: nil) }

  scope :with_get_an_identity_id, lambda {
    where.not(uid: nil)
         .where(provider: "tra_openid_connect")
  }

  EMAIL_UPDATES_STATES = %i[senco other_npq].freeze
  EMAIL_UPDATES_ALL_STATES = [:empty] + EMAIL_UPDATES_STATES

  enum email_updates_status: EMAIL_UPDATES_ALL_STATES, _suffix: true

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
    user = find_or_create_from_tra_data_on_uid(provider_data, feature_flag_id:)

    if user.persisted?
      unless user.valid?
        Rails.logger.info("[GAI] User persisted BUT not valid, #{user.errors.full_messages.join(';')}, ID=#{user.id}, UID=#{provider_data.uid}")
        Users::ArchiveByEmail.new(user:).call if user.changes[:email] && User.where(email: user.changes[:email].last).any?
      end

      return user
    end

    Rails.logger.info("[GAI] User not persisted, #{user.errors.full_messages.join(';')}, UID=#{provider_data.uid}, trying to join account")

    find_or_create_from_tra_data_on_unclaimed_email(provider_data, feature_flag_id:)
  end

  def self.find_or_create_from_tra_data_on_uid(provider_data, feature_flag_id:)
    user_from_provider_data = find_or_initialize_by(provider: provider_data.provider,
                                                    uid: provider_data.uid,
                                                    archived_at: nil)

    user_from_provider_data.assign_provider_data(provider_data)

    user_from_provider_data.assign_attributes(email: provider_data.info.email,
                                              feature_flag_id: feature_flag_id)

    user_from_provider_data.tap(&:save)
  end

  def self.find_or_create_from_tra_data_on_unclaimed_email(provider_data, feature_flag_id:)
    user_from_provider_data = find_or_initialize_by(provider: nil,
                                                    uid: nil,
                                                    email: provider_data.info.email)

    user_from_provider_data.assign_provider_data(provider_data)

    user_from_provider_data.assign_attributes(provider: provider_data.provider,
                                              uid: provider_data.uid,
                                              feature_flag_id: feature_flag_id)

    user_with_clashing_uid = User.find_by(provider: provider_data.provider, uid: provider_data.uid)
    if user_with_clashing_uid&.archived?
      Rails.logger.info("[GAI] Archived user with clashing UID found - blanking UID, ID=#{user_with_clashing_uid.id}, UID=#{provider_data.uid}")
      Users::Archiver.new(user: user_with_clashing_uid).set_uid_to_nil!
    end

    unless user_from_provider_data.save
      Rails.logger.info("[GAI] User not persisted, #{user_from_provider_data.errors.full_messages.join(';')}, ID=#{user_from_provider_data.id}, UID=#{provider_data.uid}, trying to reclaim email failed")
    end

    user_from_provider_data
  end

  def self.with_feature_flag_enabled(feature_flag_name)
    @actors = Flipper::Adapters::ActiveRecord::Gate.where(feature_key: feature_flag_name, key: "actors")
    @actors.map do |actor|
      user_uid = actor.value.split(";").last
      User.find_by(feature_flag_id: user_uid)
    end
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

  def get_an_identity_id=(new_get_an_identity_id)
    self.uid = new_get_an_identity_id
    self.provider = :tra_openid_connect
  end

  def actual_user?
    true
  end

  def null_user?
    false
  end

  def synced_to_ecf?
    ecf_id.present?
  end

  def applications_synced_to_ecf?
    applications.map(&:synced_to_ecf?).all?
  end

  def flipper_id
    "User;#{retrieve_or_persist_feature_flag_id}"
  end

  def retrieve_or_persist_feature_flag_id
    self.feature_flag_id ||= SecureRandom.uuid
    save!(validate: false) if feature_flag_id_changed?
    self.feature_flag_id
  end

  def super_admin?
    raise StandardError, "deprecated"
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

  def assign_provider_data(provider_data)
    extra_info = provider_data.extra&.raw_info

    self.raw_tra_provider_data = provider_data
    self.updated_from_tra_at = Time.zone.now
    self.full_name = extra_info&.preferred_name.presence || provider_data.info.name

    if extra_info&.birthdate.present?
      self.date_of_birth = Date.parse(extra_info.birthdate, "%Y-%m-%d")
    end

    # The user's TRN should remain unchanged if the TRA returns an empty TRN
    if extra_info&.trn.present?
      self.trn = extra_info.trn
      self.trn_verified = true
      self.trn_lookup_status = extra_info.trn_lookup_status
    end
  end

private

  def touch_significantly_updated_at
    return if skip_touch_significantly_updated_at

    changed_attributes = saved_changes.keys

    explicitly_updating_significantly_updated_at = changed_attributes.include?("significantly_updated_at")
    return if explicitly_updating_significantly_updated_at

    updated_at_touched = changed_attributes == %w[updated_at]
    significant_change = (changed_attributes - (INSIGNIFICANT_ATTRIBUTES + %w[updated_at])).any?

    update_column(:significantly_updated_at, updated_at) if updated_at_touched || significant_change
  end
end
