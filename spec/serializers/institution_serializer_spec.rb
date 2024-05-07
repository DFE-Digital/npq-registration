require "rails_helper"

RSpec.describe InstitutionSerializer, type: :serializer do
  context "when passed a institution" do
    let(:school) { build(:school, :with_address) }
    let(:hash) { InstitutionSerializer.render_as_hash(school) }

    it "only includes urn, identifier, name and address" do
      expect(hash.keys).to eq(%i[identifier name address])
    end

    it("serializes identifier") { expect(hash[:identifier]).to eql(school.identifier) }
    it("serializes name") { expect(hash[:name]).to eql(school.name) }
    it("serializes the address") { expect(hash[:address]).to eql(school.address_string) }
  end

  context "when passed a local authority" do
    let(:local_authority) { build(:local_authority) }
    let(:hash) { InstitutionSerializer.render_as_hash(local_authority) }

    it "only includes urn, identifier, name and address" do
      expect(hash.keys).to eq(%i[identifier name address])
    end

    it("serializes identifier") { expect(hash[:identifier]).to eql(local_authority.identifier) }
    it("serializes name") { expect(hash[:name]).to eql(local_authority.name) }
    it("serializes the address") { expect(hash[:address]).to eql(local_authority.address_string) }
  end
end
