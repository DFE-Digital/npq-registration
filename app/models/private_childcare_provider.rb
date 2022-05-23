class PrivateChildcareProvider < ApplicationRecord
  REDACTED_DATA_STRING = "REDACTED".freeze

  include PgSearch::Model

  pg_search_scope :search_by_name,
                  against: [:name],
                  using: {
                    tsearch: {
                      prefix: true,
                      dictionary: "english",
                    },
                  }

  pg_search_scope :search_by_urn,
                  against: [:provider_urn],
                  using: {
                    tsearch: {
                      prefix: true,
                      dictionary: "english",
                    },
                  }

  validates :provider_urn, presence: true

  def urn
    provider_urn
  end

  def ukprn
    nil
  end

  def provider_name
    raw_name = self[:provider_name]
    raw_name unless raw_name == REDACTED_DATA_STRING
  end

  def name
    provider_name
  end

  def address
    [address_1, address_2, address_3, town, region, postcode].reject(&:blank?) - [REDACTED_DATA_STRING]
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

  def on_early_years_register?
    early_years_individual_registers.include?("EYR")
  end
end
