require "rails_helper"

RSpec.describe Registration::StateStore do
  subject(:store) { create(:registration_wizard, state:).state_store }

  let :state do
    {
      started: true,
      course_start_date: "yes",
    }
  end

  it { is_expected.to have_step_attribute(:started).with_value(true) }
  it { is_expected.to have_step_attribute(:course_start_date).with_value("yes") }

  describe "#[]" do
    context "with symbol key" do
      subject { store[:course_start_date] }

      it { is_expected.to eq "yes" }
    end

    context "with string key" do
      subject { store["course_start_date"] }

      it { is_expected.to eq "yes" }
    end
  end

  describe "#not_starting_in_current_cohort?" do
    subject { store.not_starting_in_current_cohort? }

    context "without value being set" do
      let(:state) { {} }

      it { is_expected.to be false }
    end

    context "with value set to no" do
      let(:state) { { course_start_date: "yes" } }

      it { is_expected.to be false }
    end

    context "with value set to yes" do
      let(:state) { { course_start_date: "no" } }

      it { is_expected.to be true }
    end
  end
end
