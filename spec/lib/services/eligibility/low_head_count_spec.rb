require "rails_helper"

RSpec.describe Services::Eligibility::LowHeadCount do
  describe "#call" do
    context "when eligible" do
      let(:school) { build(:school, establishment_type_code: "1", number_of_pupils: 100) }

      subject { described_class.new(school: school) }

      it "returns true" do
        expect(subject.call).to be_truthy
      end
    end

    context "when correct type but pupil count to high" do
      let(:school) { build(:school, establishment_type_code: "1", number_of_pupils: 600) }

      subject { described_class.new(school: school) }

      it "returns false" do
        expect(subject.call).to be_falsey
      end
    end

    context "when incorrect type but pupil count low enough" do
      let(:school) { build(:school, establishment_type_code: "4", number_of_pupils: 100) }

      subject { described_class.new(school: school) }

      it "returns false" do
        expect(subject.call).to be_falsey
      end
    end

    context "when correct type but pupil count is zero" do
      let(:school) { build(:school, establishment_type_code: "1", number_of_pupils: 0) }

      subject { described_class.new(school: school) }

      it "returns false" do
        expect(subject.call).to be_falsey
      end
    end

    context "when correct type but pupil count is null" do
      let(:school) { build(:school, establishment_type_code: "1", number_of_pupils: nil) }

      subject { described_class.new(school: school) }

      it "returns false" do
        expect(subject.call).to be_falsey
      end
    end
  end
end
