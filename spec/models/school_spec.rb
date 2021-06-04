require "rails_helper"

RSpec.describe School do
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
  end
end
