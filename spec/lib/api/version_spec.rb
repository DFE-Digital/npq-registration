require "rails_helper"
require "api/version"

RSpec.describe API::Version do
  describe ".all" do
    subject { described_class.all }

    it { is_expected.to match_array(%i[v1 v2 v3]) }
  end

  describe ".exists?" do
    subject { described_class.exists?(version) }

    context "when the version exists" do
      let(:version) { :v3 }

      it { is_expected.to be(true) }
    end

    context "when the version does not exist" do
      let(:version) { :v0 }

      it { is_expected.to be(false) }
    end

    context "when the version is a string" do
      let(:version) { "v3" }

      it { is_expected.to be(true) }
    end
  end
end
