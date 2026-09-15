require "rails_helper"

RSpec.describe Questionnaires::YourEmployment, type: :model do
  subject(:instance) { described_class.new(employment_type:) }

  let(:employment_type) { "other" }

  describe "validations" do
    it { is_expected.to validate_presence_of(:employment_type) }
  end

  describe "#previous_step" do
    subject { instance.previous_step }

    it { is_expected.to eq(:work_setting) }
  end

  describe "#next_step" do
    subject { instance.next_step }

    context "when an employment type is hospital_school" do
      let(:employment_type) { "hospital_school" }

      it { is_expected.to be(:your_employer) }
    end

    context "when an employment type is young_offender_institution" do
      let(:employment_type) { "young_offender_institution" }

      it { is_expected.to be(:your_employer) }
    end

    context "when an employment type is other" do
      let(:employment_type) { "other" }

      it { is_expected.to be(:your_role) }
    end

    context "when an employment type is another_setting" do
      let(:employment_type) { "another_setting" }

      it { is_expected.to be(:your_role) }
    end

    context "when an employment type is local_authority_supply_teacher" do
      let(:employment_type) { "local_authority_supply_teacher" }

      it { is_expected.to be(:your_role) }
    end

    context "when an employment type is local_authority_virtual_school" do
      let(:employment_type) { "local_authority_virtual_school" }

      it { is_expected.to be(:your_role) }
    end

    context "when an employment type is lead mentor" do
      let(:employment_type) { "lead_mentor_for_accredited_itt_provider" }

      it { is_expected.to be(:itt_provider) }
    end
  end
end
