class EcfSyncRequestLog < ApplicationRecord
  belongs_to :syncable, polymorphic: true

  validates :syncable, presence: true
  validates :status, presence: true
  validates :sync_type, presence: true

  enum status: {
    success: "success",
    failed: "failed",
  }, _suffix: true

  enum sync_type: {
    user_lookup: "user_lookup",
    user_update: "user_update",
    user_creation: "user_creation",
    get_an_identity_id_sync: "get_an_identity_id_sync",
    application_creation: "application_creation",
  }, _suffix: true
end
