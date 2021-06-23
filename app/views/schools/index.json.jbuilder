json.array! @schools do |school|
  json.urn school.urn
  json.name school.name
  json.address school.address_string
end
