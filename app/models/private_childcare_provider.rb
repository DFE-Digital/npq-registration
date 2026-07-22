class PrivateChildcareProvider < ApplicationRecord
  include Disableable

  REDACTED_DATA_STRING = "REDACTED".freeze

  ELIGIBILITY_LISTS = [
    EligibilityList::DisadvantagedEarlyYearsSchool,
    EligibilityList::Childminder,
  ].map(&:name).freeze

  include PgSearch::Model

  pg_search_scope :search_by_urn,
                  against: [:provider_urn],
                  using: {
                    trigram: {
                      word_similarity: true,
                      threshold: 0.2,
                    },
                  }

  validates :provider_urn, presence: true

  has_many :urn_eligibility_entries,
           -> { where(identifier_type: "urn", type: ELIGIBILITY_LISTS) },
           class_name: "EligibilityList::Entry",
           primary_key: :provider_urn,
           foreign_key: :identifier

  def eligibility_lists = urn_eligibility_entries

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

  def display_name
    [urn, name_with_address].compact.join(" - ")
  end

  def address
    [address_1, address_2, address_3, town, region, postcode].reject(&:blank?) - [REDACTED_DATA_STRING]
  end

  def long_name
    [name, address].join(" - ")
  end

  def address_string
    address.join(", ")
  end

  def name_with_address
    [name, address_string].join(" – ")
  end

  def in_england?
    true # Needs filling in
  end

  def la_name
    local_authority
  end

  def county
    ofsted_region
  end

  def identifier
    "PrivateChildcareProvider-#{urn}"
  end

  def on_early_years_register?
    early_years_individual_registers.include?("EYR")
  end

  def eyl_disadvantaged?
    # not used, since NPQ-3719 (May 2026) - keeping for future policy changes
    EligibilityList::DisadvantagedEarlyYearsSchool.eligible?(provider_urn)
  end

  def on_childminders_list?
    EligibilityList::Childminder.eligible?(provider_urn)
  end

  def registration_details
    details = []

    details << urn
    details << (name.presence || address_string)
    details << address_string if name.presence
    details.join(" – ")
  end
end
