require "rails_helper"

RSpec.describe Migration::Ecf::NpqCourse, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:npq_applications) }
  end

  describe "#rebranded_alternative_courses" do
    let(:npq_course) { described_class.new(identifier:) }

    subject { npq_course.rebranded_alternative_courses }

    context "when the identifier is npq-additional-support-offer" do
      let(:identifier) { "npq-additional-support-offer" }

      it { is_expected.to contain_exactly(npq_course, described_class.find_by(identifier: "npq-early-headship-coaching-offer")) }
    end

    context "when the identifier is npq-early-headship-coaching-offer" do
      let(:identifier) { "npq-early-headship-coaching-offer" }

      it { is_expected.to contain_exactly(npq_course, described_class.find_by(identifier: "npq-additional-support-offer")) }
    end

    context "when the identifier is not npq-additional-support-offer or npq-early-headship-coaching-offer" do
      let(:identifier) { "other" }

      it { is_expected.to contain_exactly(npq_course) }
    end
  end
end
