class EligibilityList::LocalAuthorityNursery < EligibilityList::Entry
  IDENTIFIER_CSV_HEADERS = ["LA Nursery URN"].freeze
  IDENTIFIER_CSV_EXAMPLE = "123456\n112470".freeze
  IDENTIFIER_TYPE = :urn
end
