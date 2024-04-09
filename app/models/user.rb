class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:tra_openid_connect]

  has_many :applications, dependent: :destroy
  has_many :ecf_sync_request_logs, as: :syncable, dependent: :destroy

  validates :full_name, presence: true
  validates :email, presence: true, uniqueness: true, notify_email: true, on: :npq_separation # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :uid, uniqueness: { allow_blank: true }
  validates :uid, inclusion: { in: ->(user) { [user.uid_was] } }, on: :npq_separation, if: -> { uid_was.present? }

  scope :admins, -> { where(admin: true) }
  scope :unsynced, -> { where(ecf_id: nil) }
  scope :synced_to_ecf, -> { where.not(ecf_id: nil) }

  scope :with_get_an_identity_id, lambda {
    where.not(uid: nil)
         .where(provider: "tra_openid_connect")
  }

  EMAIL_UPDATES_STATES = %i[senco other_npq].freeze
  EMAIL_UPDATES_ALL_STATES = [:empty] + EMAIL_UPDATES_STATES

  enum email_updates_status: EMAIL_UPDATES_ALL_STATES
  def self.find_by_get_an_identity_id(get_an_identity_id)
    with_get_an_identity_id.find_by(uid: get_an_identity_id)
  end

  def self.find_or_create_from_provider_data(provider_data, feature_flag_id:)
    user = find_or_create_from_tra_data_on_uid(provider_data, feature_flag_id:)

    if user.persisted?
      unless user.valid?
        Rails.logger.info("[GAI] User persisted BUT not valid, #{user.errors.full_messages.join(';')}, ID=#{user.id}, UID=#{provider_data.uid}, trying to join account")
      end

      return user
    end

    Rails.logger.info("[GAI] User not persisted, #{user.errors.full_messages.join(';')}, ID=#{user.id}, UID=#{provider_data.uid}, trying to join account")

    find_or_create_from_tra_data_on_unclaimed_email(provider_data, feature_flag_id:)
  end

  def self.find_or_create_from_tra_data_on_uid(provider_data, feature_flag_id:)
    user_from_provider_data = find_or_initialize_by(provider: provider_data.provider, uid: provider_data.uid)
    user_from_provider_data.feature_flag_id = feature_flag_id

    trn = provider_data.info.trn

    user_from_provider_data.assign_attributes(
      email: provider_data.info.email,
      date_of_birth: provider_data.info.date_of_birth,
      trn:,
      trn_lookup_status: provider_data.info.trn_lookup_status,
      trn_verified: trn.present?,
      full_name: provider_data.info.preferred_name || provider_data.info.name,
      raw_tra_provider_data: provider_data,
      updated_from_tra_at: Time.zone.now,
    )

    user_from_provider_data.tap(&:save)
  end

  def self.find_or_create_from_tra_data_on_unclaimed_email(provider_data, feature_flag_id:)
    user_from_provider_data = find_or_initialize_by(provider: nil, uid: nil, email: provider_data.info.email)

    user_from_provider_data.feature_flag_id = feature_flag_id

    trn = provider_data.info.trn

    user_from_provider_data.assign_attributes(
      provider: provider_data.provider,
      uid: provider_data.uid,
      date_of_birth: provider_data.info.date_of_birth,
      trn:,
      trn_lookup_status: provider_data.info.trn_lookup_status,
      trn_verified: trn.present?,
      full_name: provider_data.info.preferred_name || provider_data.info.name,
      raw_tra_provider_data: provider_data,
      updated_from_tra_at: Time.zone.now,
    )

    unless user_from_provider_data.save
      Rails.logger.info("[GAI] User not persisted, #{user_from_provider_data.errors.full_messages.join(';')}, ID=#{user_from_provider_data.id}, UID=#{provider_data.uid}, trying to reclaim email failed")
    end

    user_from_provider_data
  end

  def get_an_identity_user
    return if get_an_identity_id.blank?

    External::GetAnIdentity::User.find(get_an_identity_id)
  end

  def ecf_user
    return if ecf_id.blank?

    External::EcfAPI::Npq::User.find(ecf_id).first
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

  def ecf_sync_jobs
    arel_table = Delayed::Job.arel_table
    job_name_query = arel_table[:handler].matches("%ApplicationSubmissionJob%")
    user_id_query = arel_table[:handler].matches("%_aj_globalid: gid://npq-registration/User/#{id}%")
    Delayed::Job.where(job_name_query)
                .where(user_id_query)
                .order(run_at: :asc)
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
end
