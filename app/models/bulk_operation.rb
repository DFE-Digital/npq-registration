class BulkOperation < ApplicationRecord
  belongs_to :admin
  has_one_attached :file

  scope :not_ran, -> { where(result: nil) }

  def ran?
    result.present?
  end
end
