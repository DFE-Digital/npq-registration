class BulkOperation < ApplicationRecord
  belongs_to :admin
  has_one_attached :file

  scope :not_run, -> { where(result: nil) }
end
