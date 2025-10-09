class EligibilityList::Pp50School < EligibilityList::Entry
  IDENTIFIER_CSV_HEADERS = ["PP50 School URN"].freeze
  IDENTIFIER_CSV_EXAMPLE = "100000\n100006".freeze
  IDENTIFIER_TYPE = :urn
end
