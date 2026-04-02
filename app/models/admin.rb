class Admin < ApplicationRecord
  has_many :bulk_operations

  validates :full_name, presence: true, length: { maximum: 64 }
  validates :email, presence: true, length: { maximum: 64 }

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  def name_with_email
    "#{full_name} (#{email})".tap do |name|
      name << " (archived)" if archived_at.present?
    end
  end

  def archive!
    update!(archived_at: Time.zone.now)
  end
end
