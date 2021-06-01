class School < ApplicationRecord
  include PgSearch::Model

  pg_search_scope :search_by_name, against: [:name]

  pg_search_scope :search_by_location,
                  against: %i[la_name address_1 address_2 address_3 town county postcode region]

  scope :open, -> { where(establishment_status_code: %w[1 3 4]) }

  def address
    [address_1, address_2, address_3, town, county, postcode].reject(&:blank?)
  end

  def address_string
    address.join(", ")
  end
end
