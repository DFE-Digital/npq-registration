json.array! @institutions do |institution|
  json.identifier institution.identifier
  json.name institution.name
  json.address institution.address_string
end
