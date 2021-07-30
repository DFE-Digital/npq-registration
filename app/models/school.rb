class School < ApplicationRecord
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
                  against: %i[la_name address_1 address_2 address_3 town county postcode postcode_without_spaces region]

  scope :open, -> { where(establishment_status_code: %w[1 3 4]) }

  def address
    [address_1, address_2, address_3, town, county, postcode].reject(&:blank?)
  end

  def address_string
    address.join(", ")
  end

  def in_england?
    return if establishment_type_code == "30" # Welsh establishment
    return if la_code == "673" # "Vale of Glamorgan"
    return if la_code == "702" # "BFPO Overseas Establishments"
    return if la_code == "000" # "Does not apply"
    return if la_code == "704" # "Fieldwork Overseas Establishments"
    return if la_code == "708" # "Gibraltar Overseas Establishments"

    true
  end
end
