class EligibilityList::Pp50FurtherEducation < EligibilityList::Entry
  IDENTIFIER_CSV_HEADERS = ["FE UKPRN"].freeze
  IDENTIFIER_CSV_EXAMPLE = "10000599\n10004502".freeze
  IDENTIFIER_TYPE = :ukprn
end
