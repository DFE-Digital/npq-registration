require "rails_helper"

RSpec.describe Application do
  describe "#calculate_funding_eligbility" do
    let(:mock_funding_service) { instance_double(Services::FundingEligibility, call: nil) }

    subject { build(:application) }

    it "calls Services::FundingEligibility with correct params" do
      allow(Services::FundingEligibility).to receive(:new).with(course: subject.course, institution: subject.school, new_headteacher: subject.new_headteacher?).and_return(mock_funding_service)

      subject.calculate_funding_eligbility

      expect(mock_funding_service).to have_received(:call)
    end
  end
end
