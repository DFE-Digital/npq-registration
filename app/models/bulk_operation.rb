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

  def finished?
    finished_at.present?
  end

private

  def ids_to_update
    file.open { CSV.read(_1, headers: false).flatten }
  end

  def file_valid
    return unless file.attached?

    if file.blob.byte_size.positive?
      check_format if attachment_changes["file"]
    else
      errors.add(:file, :empty)
    end
  end

  def attached_file
    attachment_changes["file"]&.attachable
  end

  def headers?
    self.class::HEADERS
  end

  def check_format
    csv = CSV.read(attached_file, headers: headers?)

    if headers?
      errors.add(:file, :empty) if csv.count.zero?
      errors.add(:file, :invalid) if (self.class::FILE_HEADERS - csv.headers).any?
    elsif csv.first.many?
      errors.add(:file, :invalid)
    end
  rescue CSV::MalformedCSVError => e
    errors.add(:file, e.message)
  end

  def update_row_count
    return unless attachment_changes["file"]

    self.row_count = CSV.read(attached_file, headers: headers?).count
  end
end
