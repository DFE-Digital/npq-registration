require "rails_helper"

RSpec.describe Course do
  subject { build(:course) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:identifier).with_message("Identifier already exists, enter a unique one") }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique").allow_nil }
  end

  describe "associations" do
    it { is_expected.to belong_to(:course_group).optional }
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

  describe "#aso?" do
    it { expect(described_class.new(identifier: "npq-additional-support-offer")).to be_aso }
    it { expect(described_class.new(identifier: "other")).not_to be_aso }
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

  describe "#schedule_for" do
    let(:cohort) { build(:cohort, :current) }
    let(:schedule_date) { Date.current }

    it "calls course_group.schedule_for method" do
      expect(subject.course_group).to receive(:schedule_for).with(cohort:, schedule_date:)
      subject.schedule_for(cohort:, schedule_date:)
    end
  end

  describe "#short_code" do
    let(:course) { create(:course, :senior_leadership) }

    it "returns the short code" do
      expect(course.short_code).to eq("NPQSL")
    end

    context "when a NPQ course short code is missing from the mapping" do
      let(:course) { create(:course, identifier: "npq-anything") }

      it "logs an error" do
        expect(Rails.logger).to receive(:warn)
        expect(Sentry).to receive(:capture_exception)

        course.short_code
      end

      it "returns nil" do
        expect(course.short_code).to be_nil
      end
    end
  end
end
