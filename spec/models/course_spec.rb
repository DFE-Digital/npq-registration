require "rails_helper"

RSpec.describe Course do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:identifier).with_message("Identifier already exists, enter a unique one") }
  end

  describe "associations" do
    it { is_expected.to belong_to(:course_group) }
  end

  describe ".ehco" do
    it { expect(described_class.ehco).to eq(described_class.find_by(identifier: "npq-early-headship-coaching-offer")) }
  end

  describe ".npqltd" do
    it { expect(described_class.npqltd).to eq(described_class.find_by(identifier: "npq-leading-teaching-development")) }
  end

  describe ".npqeyl" do
    it { expect(described_class.npqeyl).to eq(described_class.find_by(identifier: "npq-early-years-leadership")) }
  end

  describe "#eyl?" do
    it { expect(described_class.new(identifier: "npq-early-years-leadership")).to be_eyl }
    it { expect(described_class.new(identifier: "other")).not_to be_eyl }
  end

  describe "#npqh?" do
    it { expect(described_class.new(identifier: "npq-headship")).to be_npqh }
    it { expect(described_class.new(identifier: "other")).not_to be_npqh }
  end

  describe "#ehco?" do
    it { expect(described_class.new(identifier: "npq-early-headship-coaching-offer")).to be_ehco }
    it { expect(described_class.new(identifier: "other")).not_to be_ehco }
  end

  describe "#npqltd?" do
    it { expect(described_class.new(identifier: "npq-leading-teaching-development")).to be_npqltd }
    it { expect(described_class.new(identifier: "other")).not_to be_npqltd }
  end

  describe "#npqlpm?" do
    it { expect(described_class.new(identifier: "npq-leading-primary-mathematics")).to be_npqlpm }
    it { expect(described_class.new(identifier: "other")).not_to be_npqlpm }
  end

  describe "#rebranded_alternative_courses" do
    let(:course) { described_class.new(identifier:) }

    subject { course.rebranded_alternative_courses }

    context "when the identifier is npq-additional-support-offer" do
      let(:identifier) { "npq-additional-support-offer" }

      it { is_expected.to contain_exactly(course, described_class.find_by(identifier: "npq-early-headship-coaching-offer")) }
    end

    context "when the identifier is npq-early-headship-coaching-offer" do
      let(:identifier) { "npq-early-headship-coaching-offer" }

      it { is_expected.to contain_exactly(course, described_class.find_by(identifier: "npq-additional-support-offer")) }
    end

    context "when the identifier is not npq-additional-support-offer or npq-early-headship-coaching-offer" do
      let(:identifier) { "other" }

      it { is_expected.to contain_exactly(course) }
    end
  end
end
