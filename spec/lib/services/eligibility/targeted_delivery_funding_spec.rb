require "rails_helper"

RSpec.describe Eligibility::TargetedDeliveryFunding do
  subject { described_class.call(institution:, course:) }

  describe ".call" do
    unsupported_course_codes = %w[npq-early-headship-coaching-offer].freeze
    supported_course_codes = Course::IDENTIFIERS - unsupported_course_codes

    let(:course) { Course.find_by!(identifier: supported_course_codes.sample) }

    context "when eligible" do
      let(:institution) { build(:school, establishment_type_code: "1", number_of_pupils: 100) }

      it "returns true" do
        expect(subject).to be_truthy
      end
    end

    unsupported_course_codes.each do |course_code|
      context "when applying for #{course_code}" do
        let(:course) { Course.find_by!(identifier: course_code) }
        let(:institution) { build(:school, establishment_type_code: "1", number_of_pupils: 100) }

        it "returns false" do
          expect(subject).to be_falsey
        end
      end
    end

    supported_course_codes.each do |course_code|
      context "when applying for #{course_code}" do
        let(:course) { Course.find_by!(identifier: course_code) }
        let(:institution) { build(:school, establishment_type_code: "1", number_of_pupils: 100) }

        it "returns true" do
          expect(subject).to be_truthy
        end
      end
    end

    context "when institution is an LA" do
      let(:institution) { build(:local_authority) }

      it "returns false" do
        expect(subject).to be_falsey
      end
    end

    context "when correct type but pupil count to high" do
      let(:institution) { build(:school, establishment_type_code: "1", number_of_pupils: 601) }

      it "returns false" do
        expect(subject).to be_falsey
      end
    end

    context "when incorrect type but pupil count low enough" do
      let(:institution) { build(:school, establishment_type_code: "4", number_of_pupils: 100) }

      it "returns false" do
        expect(subject).to be_falsey
      end
    end

    context "when correct type but pupil count is zero" do
      let(:institution) { build(:school, establishment_type_code: "1", number_of_pupils: 0) }

      it "returns false" do
        expect(subject).to be_falsey
      end
    end

    context "when correct type but pupil count is null" do
      let(:institution) { build(:school, establishment_type_code: "1", number_of_pupils: nil) }

      it "returns false" do
        expect(subject).to be_falsey
      end
    end

    context "when FE applicable body" do
      let(:institution) { build(:school, ukprn: "10000350", number_of_pupils: 1000) }

      it "returns true" do
        expect(subject).to be_truthy
      end
    end
  end
end
