require "rails_helper"

RSpec.describe Services::Admin::SchoolsSearch do
  subject { described_class.new(q:) }

  let!(:school) { create(:school) }

  describe "#call" do
    context "when partial name match" do
      let(:q) { school.name.split(" ").first }

      it "returns the hit" do
        expect(subject.call).to include(school)
      end
    end

    context "when school#urn match" do
      let(:q) { school.urn }

      it "returns the hit" do
        expect(subject.call).to include(school)
      end
    end
  end
end
