class LocalAuthority < ApplicationRecord
  include PgSearch::Model

  pg_search_scope :search_by_name,
                  against: %i[name address_1 address_2 address_3 town county postcode postcode_without_spaces],
                  using: {
                    tsearch: {
                      prefix: true,
                      dictionary: "english",
                    },
                  }

  def eligibility_lists = []
  def display_name = name
  def urn = nil
  def identifier = "LocalAuthority-#{id}"
  def in_england? = true
  def la_name = name

  def address
    [address_1, address_2, address_3, town, county, postcode].reject(&:blank?)
  end

  def address_string
    address.join(", ")
  end

  def name_with_address
    [display_name, address_string].join(" – ")
  end
end
