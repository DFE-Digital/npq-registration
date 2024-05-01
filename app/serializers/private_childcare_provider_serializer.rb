class PrivateChildcareProviderSerializer < Blueprinter::Base
  exclude(:id)
  field(:identifier)
  field(:urn)
  field(:name)
  field(:address) { |pcp, _| pcp.address_string }
end
