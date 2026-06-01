require "rails_helper"

RSpec.describe InstitutionSerializer, type: :serializer do
  context "when passed a institution" do
    let(:school) { build(:school, :with_address) }
    let(:hash) { InstitutionSerializer.render_as_hash(school) }

    it "only includes identifier, urn, name and address" do
      expect(hash.keys).to eq(%i[identifier urn name address])
    end

    it("serializes identifier") { expect(hash[:identifier]).to eql(school.identifier) }
    it("serializes urn") { expect(hash[:urn]).to eql(school.urn) }
    it("serializes name") { expect(hash[:name]).to eql(school.name) }
    it("serializes the address") { expect(hash[:address]).to eql(school.address_string) }
  end

  context "when passed a local authority" do
    let(:local_authority) { build(:local_authority) }
    let(:hash) { InstitutionSerializer.render_as_hash(local_authority) }

    it "only includes identifier, urn, name and address" do
      expect(hash.keys).to eq(%i[identifier urn name address])
    end

    it("serializes identifier") { expect(hash[:identifier]).to eql(local_authority.identifier) }
    it("serializes a nil urn") { expect(hash[:urn]).to be_nil }
    it("serializes name") { expect(hash[:name]).to eql(local_authority.name) }
    it("serializes the address") { expect(hash[:address]).to eql(local_authority.address_string) }
  end
end
