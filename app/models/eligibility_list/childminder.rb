class EligibilityList::Childminder < EligibilityList::Entry
  IDENTIFIER_CSV_HEADERS = ["Childminder URN"].freeze
  IDENTIFIER_CSV_EXAMPLE = "CA000006\nEY248638\n225540".freeze
  IDENTIFIER_TYPE = :urn
end
