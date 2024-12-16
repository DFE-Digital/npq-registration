class BulkOperation < ApplicationRecord
  belongs_to :admin
  has_one_attached :file

  validate :file_valid

  scope :not_ran, -> { where(result: nil) }

  def ran?
    result.present?
  end

  def file_valid
    return unless file.attached?

    errors.add(:file, "is empty") unless file.blob.byte_size.positive?
    if attachment_changes["file"]
      check_format(attachment_changes["file"].attachable.read)
    else
      check_format(file.blob.open(&:read))
    end
  end

private

  def check_format(string)
    CSV.parse(string) do |row|
      if row.size > 1
        errors.add(:file, "is wrong format")
        break
      end
    end
  end
end
