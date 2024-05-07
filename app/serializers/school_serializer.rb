class SchoolSerializer < Blueprinter::Base
  exclude(:id)
  field(:urn)
  field(:name)
  field(:address) { |s, _| s.address_string }
end
