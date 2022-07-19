require "rails_helper"

RSpec.describe Services::Eligibility::TargetedDeliveryFunding do
  unsupported_course_codes = %w[
    EHCO
    ASO
  ].freeze
  supported_course_codes = Course::COURSE_NAMES.keys - unsupported_course_codes

  describe "#call" do
    let(:course_name) { Course::COURSE_NAMES[supported_course_codes.sample] }
    let(:course) { Course.find_by!(name: course_name) }

    context "when eligible" do
      let(:institution) { build(:school, establishment_type_code: "1", number_of_pupils: 100) }

      subject { described_class.new(institution:, course:) }

      it "returns true" do
        expect(subject.call).to be_truthy
      end
    end

    unsupported_course_codes.each do |course_code|
      course_name = Course::COURSE_NAMES[course_code]

      context "when applying for #{course_code}" do
        let(:course) { Course.find_by!(name: course_name) }
        let(:institution) { build(:school, establishment_type_code: "1", number_of_pupils: 100) }

        subject { described_class.new(institution:, course:) }

        it "returns false" do
          expect(subject.call).to be_falsey
        end
      end
    end

    supported_course_codes.each do |course_code|
      course_name = Course::COURSE_NAMES[course_code]

      context "when applying for #{course_code}" do
        let(:course) { Course.find_by!(name: course_name) }
        let(:institution) { build(:school, establishment_type_code: "1", number_of_pupils: 100) }

        subject { described_class.new(institution:, course:) }

        it "returns true" do
          expect(subject.call).to be_truthy
        end
      end
    end

    context "when institution is an LA" do
      let(:institution) { build(:local_authority) }

      subject { described_class.new(institution:, course:) }

      it "returns false" do
        expect(subject.call).to be_falsey
      end
    end

    context "when correct type but pupil count to high" do
      let(:institution) { build(:school, establishment_type_code: "1", number_of_pupils: 600) }

      subject { described_class.new(institution:, course:) }

      it "returns false" do
        expect(subject.call).to be_falsey
      end
    end

    context "when incorrect type but pupil count low enough" do
      let(:institution) { build(:school, establishment_type_code: "4", number_of_pupils: 100) }

      subject { described_class.new(institution:, course:) }

      it "returns false" do
        expect(subject.call).to be_falsey
      end
    end

    context "when correct type but pupil count is zero" do
      let(:institution) { build(:school, establishment_type_code: "1", number_of_pupils: 0) }

      subject { described_class.new(institution:, course:) }

      it "returns false" do
        expect(subject.call).to be_falsey
      end
    end

    context "when correct type but pupil count is null" do
      let(:institution) { build(:school, establishment_type_code: "1", number_of_pupils: nil) }

      subject { described_class.new(institution:, course:) }

      it "returns false" do
        expect(subject.call).to be_falsey
      end
    end

    context "when FE applicable body" do
      let(:institution) { build(:school, ukprn: "10000350", number_of_pupils: 1000) }

      subject { described_class.new(institution:, course:) }

      it "returns true" do
        expect(subject.call).to be_truthy
      end
    end
  end
end
