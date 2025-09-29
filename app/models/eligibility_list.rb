class EligibilityList < ApplicationRecord
  before_validation :set_identifier_type

  def self.eligible?(identifier)
    exists?(identifier:)
  end

  def self.last_updated_at
    last&.created_at
  end

private

  def set_identifier_type
    self.identifier_type ||= self.class::IDENTIFIER_TYPE
  end
end
