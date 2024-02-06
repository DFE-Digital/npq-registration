class Participant < ApplicationRecord
  scope :unsynced, -> { where(ecf_id: nil) }
  scope :synced, -> { where.not(ecf_id: nil) }
end
