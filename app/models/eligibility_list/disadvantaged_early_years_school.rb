class EligibilityList::DisadvantagedEarlyYearsSchool < EligibilityList::Entry
  IDENTIFIER_CSV_HEADERS = ["Disadvantaged EY School URN", "Ofsted URN"].freeze
  IDENTIFIER_CSV_EXAMPLE = "150014,\n531156,EY555509".freeze
  IDENTIFIER_TYPE = :urn
end
