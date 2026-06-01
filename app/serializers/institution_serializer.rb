class InstitutionSerializer < Blueprinter::Base
  exclude(:id)
  field(:identifier)
  field(:urn)
  field(:name)
  field(:address) { |i, _| i.address_string }
end
