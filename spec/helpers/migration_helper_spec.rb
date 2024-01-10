require "rails_helper"

RSpec.describe MigrationHelper, type: :helper do
  describe "#migration_result_attributes" do
    let(:result) { create(:migration_result) }

    it "returns the attributes that match the given key" do
      expect(helper.migration_result_attributes(result, "users")).to match_array(
        %w[
          users_count
          orphaned_ecf_users_count
          orphaned_npq_users_count
          duplicate_users_count
          matched_users_count
        ],
      )
    end
  end

  describe "#migration_result_summary_row" do
    subject { helper.migration_result_summary_row(result, "users", "orphaned_ecf_users_count") }

    let(:result) { create(:migration_result, orphaned_ecf_users_count: 8, users_count: 11) }

    it "returns a summary row for the given attribute" do
      expect(subject).to have_css(".govuk-summary-list__row")
      expect(subject).to have_css(".govuk-summary-list__key", text: "Orphaned ecf")
      expect(subject).to have_css(".govuk-summary-list__value", text: result.orphaned_ecf_users_count)
      expect(subject).to have_css(".govuk-summary-list__actions .govuk-tag--red", text: "73%")
    end
  end

  describe "#migration_result_percentage_color" do
    subject { helper.migration_result_percentage_color("users", attribute, value) }

    context "when the attribute is matched and the value is greater than zero" do
      let(:value) { 1 }
      let(:attribute) { "matched_users_count" }

      it { is_expected.to eq(:green) }
    end

    context "when the attribute is matched and the value is zero" do
      let(:value) { 0 }
      let(:attribute) { "matched_users_count" }

      it { is_expected.to be_nil }
    end

    context "when the value is greater than zero and the attribute is not the total count" do
      let(:value) { 1 }
      let(:attribute) { "orphaned_ecf_users_count" }

      it { is_expected.to eq(:red) }
    end

    context "when the value is zero and the attribute is not the total count" do
      let(:value) { 0 }
      let(:attribute) { "orphaned_ecf_users_count" }

      it { is_expected.to be_nil }
    end

    context "when the value is greater than zero and the attribute is the total count" do
      let(:value) { 1 }
      let(:attribute) { "users_count" }

      it { is_expected.to be_nil }
    end

    context "when the value is zero and the attribute is the total count" do
      let(:value) { 0 }
      let(:attribute) { "users_count" }

      it { is_expected.to be_nil }
    end
  end
end
