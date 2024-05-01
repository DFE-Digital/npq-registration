require "rails_helper"

RSpec.describe PrivateChildcareProviderSerializer, type: :serializer do
  let(:private_childcare_provider) { build(:private_childcare_provider) }
  let(:hash) { PrivateChildcareProviderSerializer.render_as_hash(private_childcare_provider) }

  it "only includes urn, identifier, name and address" do
    expect(hash.keys).to eq(%i[identifier urn name address])
  end

  it("includes the urn") { expect(hash[:urn]).to eql(private_childcare_provider.urn) }
  it("includes the identifier") { expect(hash[:identifier]).to eql(private_childcare_provider.identifier) }
  it("includes the name") { expect(hash[:name]).to eql(private_childcare_provider.name) }
  it("includes the address") { expect(hash[:address]).to eql(private_childcare_provider.address_string) }
end
