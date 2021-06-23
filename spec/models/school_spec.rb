require "rails_helper"

RSpec.describe School do
  describe "::search_by_name" do
    context "regarding apostrophes" do
      before do
        create(:school, name: "andrew's")
      end

      it "can find with apostrophe" do
        expect(described_class.search_by_name("andrew's").count).to eql(1)
      end

      it "can find without apostrophe" do
        expect(described_class.search_by_name("andrews").count).to eql(1)
      end

      it "can find partial match" do
        expect(described_class.search_by_name("andrew").count).to eql(1)
      end
    end

    context "regarding hyphesn" do
      before do
        create(:school, name: "mary-anne")
      end

      it "can find with hyphen" do
        expect(described_class.search_by_name("mary-anne").count).to eql(1)
      end

      it "can find without hyphen" do
        expect(described_class.search_by_name("mary anne").count).to eql(1)
      end

      it "can find partial match" do
        expect(described_class.search_by_name("mary").count).to eql(1)
      end
    end
  end

  describe "#in_england?" do
    it "returns true" do
      expect(subject.in_england?).to be_truthy
    end

    context "when school establishment_type_code is 30 (Welsh establishment)" do
      before do
        subject.establishment_type_code = "30"
      end

      it "returns false" do
        expect(subject.in_england?).to be_falsey
      end
    end

    context "when school la_code is '673' (Vale of Glamorgan)" do
      before do
        subject.la_code = "673"
      end

      it "returns false" do
        expect(subject.in_england?).to be_falsey
      end
    end

    context "when school la_code is '702' (BFPO Overseas Establishments)" do
      before do
        subject.la_code = "702"
      end

      it "returns false" do
        expect(subject.in_england?).to be_falsey
      end
    end

    context "when school la_code is '000' (Does not apply)" do
      before do
        subject.la_code = "000"
      end

      it "returns false" do
        expect(subject.in_england?).to be_falsey
      end
    end

    context "when school la_code is '704' (Fieldwork Overseas Establishments)" do
      before do
        subject.la_code = "704"
      end

      it "returns false" do
        expect(subject.in_england?).to be_falsey
      end
    end

    context "when school la_code is '708' (Gibraltar Overseas Establishments)" do
      before do
        subject.la_code = "708"
      end

      it "returns false" do
        expect(subject.in_england?).to be_falsey
      end
    end
  end
end
