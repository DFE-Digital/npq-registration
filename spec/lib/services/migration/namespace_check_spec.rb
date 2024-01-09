require "rails_helper"

RSpec.describe Migration::NamespaceCheck do
  describe "#ecf?" do
    it "returns true if the object is an ECF object" do
      expect(described_class.ecf?(Migration::Ecf::NpqApplication.new)).to eq(true)
    end

    it "returns false if the object is not an ECF object" do
      expect(described_class.ecf?(Application.new)).to eq(false)
    end
  end

  describe "#npq?" do
    it "returns true if the object is an NPQ object" do
      expect(described_class.npq?(Application.new)).to eq(true)
    end

    it "returns false if the object is not an NPQ object" do
      expect(described_class.npq?(Migration::Ecf::NpqApplication.new)).to eq(false)
    end
  end
end
