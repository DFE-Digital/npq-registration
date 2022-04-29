class PrivateChildcareProvider < ApplicationRecord
  include PgSearch::Model

  pg_search_scope :search_by_name,
                  against: [:name],
                  using: {
                    tsearch: {
                      prefix: true,
                      dictionary: "english",
                    },
                  }

  validates :provider_urn, presence: true

  def address
    [address_1, address_2, address_3, town, postcode, region].reject(&:blank?)
  end

  def address_string
    address.join(", ")
  end

  def in_england?
    true # Needs filling in
  end

  def identifier
    "PrivateChildcareProvider-#{urn}"
  end
end
