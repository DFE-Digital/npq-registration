class BulkOperation < ApplicationRecord
  belongs_to :admin
  has_one_attached :file

  validate :file_valid

  scope :not_started, -> { where(started_at: nil) }

  def started?
    started_at.present?
  end

private

  def file_valid
    return unless file.attached?

    errors.add(:file, :empty) unless file.blob.byte_size.positive?
    if attachment_changes["file"]
      check_format(attachment_changes["file"].attachable.read)
    end
  end

  def check_format(string)
    CSV.parse(string) do |row|
      if row.size > 1
        errors.add(:file, :invalid)
        break
      end
    end
  rescue CSV::MalformedCSVError
    errors.add(:file, :malformed)
  end
end
