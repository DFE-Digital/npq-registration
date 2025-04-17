class BulkOperation < ApplicationRecord
  belongs_to :admin
  belongs_to :ran_by_admin, class_name: "Admin", optional: true
  has_one_attached :file

  validate :file_valid

  before_save :update_row_count

  scope :not_started, -> { where(started_at: nil) }

  HEADERS = false

  def started?
    started_at.present?
  end

  def ids_to_update
    file.open { CSV.read(_1, headers: false).flatten }
  end

private

  def file_valid
    return unless file.attached?

    if file.blob.byte_size.positive?
      check_format if attachment_changes["file"]
    else
      errors.add(:file, :empty)
    end
  end

  def attached_file
    attachment_changes["file"].attachable
  end

  def headers?
    self.class::HEADERS
  end

  def check_format
    first_row = CSV.read(attached_file, headers: false).first
    errors.add(:file, :invalid) if first_row.many?
  rescue CSV::MalformedCSVError
    errors.add(:file, :malformed)
  end

  def update_row_count
    return unless attachment_changes["file"]

    self.row_count = CSV.read(attached_file, headers: headers?).count
  end
end
