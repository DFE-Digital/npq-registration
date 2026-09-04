require "rails_helper"

RSpec.describe Questionnaires::YourEmployer, type: :model do
  subject(:instance) { described_class.new(wizard:, employer_name:) }

  let(:wizard) { RegistrationWizard.new(current_step: :your_employer, store:, request: nil, current_user: nil) }
  let(:store) { { course_identifier: course.identifier, employment_type: }.stringify_keys }
  let(:course) { Course.first }
  let(:employer_name) { nil }
  let(:employment_type) { nil }

  describe "validations" do
    it { is_expected.to validate_presence_of(:employer_name) }
  end

  describe "#previous_step" do
    context "when the employment type is hospital school" do
      let(:employment_type) { Application.employment_types[:hospital_school] }

      it { expect(instance.previous_step).to eq(:your_employment) }
    end

    context "when the employment type is young offender institution" do
      let(:employment_type) { Application.employment_types[:young_offender_institution] }

      it { expect(instance.previous_step).to eq(:your_employment) }
    end

    context "when the employment type is neither hospital school nor young offender institution" do
      Application.employment_types.except(:hospital_school, :young_offender_institution).each do |employment_type|
        context "when the employment type is #{employment_type}" do
          let(:employment_type) { Application.employment_types[employment_type] }

          it { expect(instance.previous_step).to eq(:your_role) }
        end
      end
    end
  end

  describe "#next_step" do
    subject { instance.next_step }

    it_behaves_like "showing the eligibility step"
  end
end
