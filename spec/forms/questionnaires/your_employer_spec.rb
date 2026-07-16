require "rails_helper"

RSpec.describe Questionnaires::YourEmployer, type: :model do
  subject(:instance) { described_class.new(employer_name:) }

  let(:employer_name) { nil }

  describe "validations" do
    it { is_expected.to validate_presence_of(:employer_name) }
  end

  describe "#next_step" do
    subject { instance.next_step }

    it_behaves_like "showing the eligibility step"
  end
end
