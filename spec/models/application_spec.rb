require "rails_helper"

RSpec.describe Application do
  describe "#calculate_funding_eligbility" do
    let(:mock_funding_service) { instance_double(Services::FundingEligibility, "funded?": true) }

    subject { create(:application, kind_of_application) }

    context "application_for_school" do
      let(:kind_of_application) { :application_for_school }

      it "calls Services::FundingEligibility with correct params" do
        allow(Services::FundingEligibility).to receive(:new).with(
          course: subject.course,
          institution: subject.school,
          inside_catchment: subject.inside_catchment?,
          new_headteacher: subject.new_headteacher?,
          trn: subject.user.trn,
          ).and_return(mock_funding_service)

        subject.calculate_funding_eligbility

        expect(mock_funding_service).to have_received(:funded?)
      end
    end

    context "application_for_private_childcare_provider" do
      let(:kind_of_application) { :application_for_private_childcare_provider }

      it "calls Services::FundingEligibility with correct params" do
        allow(Services::FundingEligibility).to receive(:new).with(
          course: subject.course,
          institution: subject.private_childcare_provider,
          inside_catchment: subject.inside_catchment?,
          new_headteacher: subject.new_headteacher?,
          trn: subject.user.trn,
          ).and_return(mock_funding_service)

        subject.calculate_funding_eligbility

        expect(mock_funding_service).to have_received(:funded?)
      end
    end

    context "application_for_public_childcare_provider" do
      let(:kind_of_application) { :application_for_public_childcare_provider }

      it "calls Services::FundingEligibility with correct params" do
        allow(Services::FundingEligibility).to receive(:new).with(
          course: subject.course,
          institution: subject.school,
          inside_catchment: subject.inside_catchment?,
          new_headteacher: subject.new_headteacher?,
          trn: subject.user.trn,
          ).and_return(mock_funding_service)

        subject.calculate_funding_eligbility

        expect(mock_funding_service).to have_received(:funded?)
      end
    end
  end
end
