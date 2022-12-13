require "rails_helper"

RSpec.describe Forms::YourEmployment, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:employment_type) }
  end

  describe "#next_step" do
    let(:other_employment_values) do
      %w[
        local_authority_virtual_school
        hospital_school
        young_offender_institution
        local_authority_supply_teacher
        other
      ]
    end

    subject do
      described_class.new(employment_type:)
    end

    context "when an employment type is anything but lead mentor" do
      other_employment_values.each do |employment|
        let(:employment_type) { employment }

        it "returns your_role" do
          expect(subject.next_step).to eql(:your_role)
        end
      end
    end

    context "when an employment type is lead mentor" do
      let(:employment_type) { "lead_mentor_for_accredited_itt_provider" }

      it "returns itt_provider" do
        expect(subject.next_step).to eql(:itt_provider)
      end
    end
  end
end
