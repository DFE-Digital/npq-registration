require "rails_helper"

RSpec.describe Questionnaires::YourEmployment, type: :model do
  subject do
    described_class.new(employment_type:)
  end

  let(:employment_type) { "other" }

  describe "validations" do
    it { is_expected.to validate_presence_of(:employment_type) }
  end

  describe "#next_step" do
    other_employment_values =
      %w[
        local_authority_virtual_school
        hospital_school
        young_offender_institution
        local_authority_supply_teacher
        other
      ]

    other_employment_values.each do |employment_value|
      context "when an employment type is #{employment_value}" do
        let(:employment_type) { employment_value }

        it "returns your_role" do
          expect(subject.next_step).to be(:your_role)
        end
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
