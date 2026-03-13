class BulkOperation < ApplicationRecord
  belongs_to :admin
  belongs_to :ran_by_admin, class_name: "Admin", optional: true
  has_one_attached :file

  validate :file_valid

  before_save :update_row_count

  scope :not_started, -> { where(started_at: nil) }

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
    defined?(self.class::FILE_HEADERS) && file_headers.any?
  end

  def file_headers
    self.class::FILE_HEADERS
  end

  def check_format
    if headers?
      errors.add(:file, :empty) if csv_from_file_upload.count.zero?
      errors.add(:file, :invalid) if (file_headers - csv_from_file_upload.headers).any?
    elsif csv_from_file_upload.first.many?
      errors.add(:file, :invalid)
    end
  rescue CSV::MalformedCSVError => e
    errors.add(:file, e.message)
  end

  def csv_from_file_upload
    @csv_from_file_upload ||= CSV.read(attached_file, headers: headers?, header_converters: ->(header) { header&.strip })
  rescue CSV::InvalidEncodingError
    @csv_from_file_upload ||= CSV.read(attached_file, encoding: "ISO-8859-1", headers: headers?, header_converters: ->(header) { header&.strip })
  end

  def csv_from_active_storage
    @csv_from_active_storage ||= file.open { CSV.read(_1, headers: headers?, header_converters: ->(header) { header&.strip }) }
  rescue CSV::InvalidEncodingError
    @csv_from_active_storage ||= file.open { CSV.read(_1, encoding: "ISO-8859-1", headers: headers?, header_converters: ->(header) { header&.strip }) }
  end

  def update_row_count
    return unless attachment_changes["file"]

    self.row_count = csv_from_file_upload.count
  end
end
