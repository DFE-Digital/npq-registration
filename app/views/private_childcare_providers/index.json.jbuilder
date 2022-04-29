json.array! @private_childcare_providers do |private_childcare_provider|
  json.identifier private_childcare_provider.identifier
  json.urn private_childcare_provider.urn
  json.name private_childcare_provider.name
  json.address private_childcare_provider.address_string
end
