class LocalAuthority < ApplicationRecord
  include PgSearch::Model

  pg_search_scope :search_by_name,
                  against: [:name],
                  using: {
                    tsearch: {
                      prefix: true,
                      dictionary: "english",
                    },
                  }

  pg_search_scope :search_by_location,
                  against: %i[address_1 address_2 address_3 town county postcode postcode_without_spaces]

  def urn
    nil
  end

  def address
    [address_1, address_2, address_3, town, county, postcode].reject(&:blank?)
  end

  def address_string
    address.join(", ")
  end
end
