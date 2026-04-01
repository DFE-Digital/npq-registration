require "rails_helper"

RSpec.describe Questionnaires::YourEmployment, type: :model do
  subject do
    described_class.new(employment_type:)
  end

  let(:employment_type) { "other" }

  describe "validations" do
    it { is_expected.to validate_presence_of(:employment_type) }
  end

  describe "#next_step", skip: Rails.configuration.x.dfe_wizard do
    context "when an employment type is hospital_school" do
      let(:employment_type) { "hospital_school" }

      it "returns your_employer" do
        expect(subject.next_step).to be(:your_employer)
      end
    end

    context "when an employment type is young_offender_institution" do
      let(:employment_type) { "young_offender_institution" }

      it "returns your_employer" do
        expect(subject.next_step).to be(:your_employer)
      end
    end

    context "when an employment type is other" do
      let(:employment_type) { "other" }

      it "returns your_employer" do
        expect(subject.next_step).to be(:your_role)
      end
    end

    context "when an employment type is another_setting" do
      let(:employment_type) { "another_setting" }

      it "returns your_employer" do
        expect(subject.next_step).to be(:your_role)
      end
    end

    context "when an employment type is local_authority_supply_teacher" do
      let(:employment_type) { "local_authority_supply_teacher" }

      it "returns your_employer" do
        expect(subject.next_step).to be(:your_role)
      end
    end

    context "when an employment type is local_authority_virtual_school" do
      let(:employment_type) { "local_authority_virtual_school" }

      it "returns your_employer" do
        expect(subject.next_step).to be(:your_role)
      end
    end

    context "when an employment type is lead mentor" do
      let(:employment_type) { "lead_mentor_for_accredited_itt_provider" }

      it "returns itt_provider" do
        expect(subject.next_step).to be(:itt_provider)
      end
    end
  end
end
