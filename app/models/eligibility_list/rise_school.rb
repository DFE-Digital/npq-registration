class EligibilityList::RiseSchool < EligibilityList::Entry
  IDENTIFIER_CSV_HEADERS = ["RISE School URN"].freeze
  IDENTIFIER_CSV_EXAMPLE = "112543\n112578".freeze
  IDENTIFIER_TYPE = :urn
end
