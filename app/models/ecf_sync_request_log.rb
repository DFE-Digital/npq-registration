class EcfSyncRequestLog < ApplicationRecord
  belongs_to :syncable, polymorphic: true

  validates :syncable, presence: true
  validates :status, presence: true
  validates :sync_type, presence: true

  enum status: {
    success: "success",
    failed: "failed",
  }
  enum sync_type: {
    user_creation: "user_creation",
    application_creation: "application_creation",
  }
end
