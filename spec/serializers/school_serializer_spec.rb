require "rails_helper"

RSpec.describe SchoolSerializer, type: :serializer do
  let(:school) { build(:school, :with_address) }
  let(:hash) { SchoolSerializer.render_as_hash(school) }

  it "only includes urn, identifier, name and address" do
    expect(hash.keys).to eq(%i[urn name address])
  end

  it("serializes urn") { expect(hash[:urn]).to eql(school.urn) }
  it("serializes name") { expect(hash[:name]).to eql(school.name) }
  it("serializes the address") { expect(hash[:address]).to eql(school.address_string) }
end
