json.array! @institutions do |institution|
  json.urn institution.urn
  json.ukprn institution.ukprn
  json.name institution.name
  json.address institution.address_string
end
