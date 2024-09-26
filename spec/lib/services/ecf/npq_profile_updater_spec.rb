require "rails_helper"

RSpec.describe Ecf::NpqProfileUpdater do
  subject { described_class.new(application:) }

  let(:user) do
    User.create!(
      email: "john.doe@example.com",
      full_name: "John Doe",
      ecf_id: "f661f5af-c6ec-4b38-8582-8f50107a3918",
      trn: "1234567",
      trn_verified: true,
      active_alert: true,
      date_of_birth: Date.new(1980, 12, 13),
      national_insurance_number: "AB123456C",
    )
  end
  let!(:update_ecf_stub) do
    stub_request(:patch, "https://ecf-app.gov.uk/api/v1/npq-profiles/#{application.ecf_id}")
      .with(
        body: request_body,
        headers: {
          "Accept" => "application/vnd.api+json",
          "Authorization" => "Bearer ECFAPPBEARERTOKEN",
          "Content-Type" => "application/vnd.api+json",
        },
      )
        .to_return(
          status: 200,
          body: response_body,
          headers: {
            "Content-Type" => "application/vnd.api+json",
          },
        )
  end
  let(:course) { create(:course, name: "Some course", ecf_id: "d182edb5-2f5a-4ad3-a897-8cce0650ae93") }
  let(:lead_provider) { LeadProvider.create!(name: "Some lead provider", ecf_id: "73ab3215-0403-4de1-a537-066dae9ded60") }
  let(:school) { create(:school) }

  let(:old_teacher_catchment) { "england" }
  let(:old_teacher_catchment_country) { nil }
  let(:new_teacher_catchment) { "other" }
  let(:new_teacher_catchment_country) { "United Kingdom" }

  let(:application) do
    Application.create!(
      user:,
      course:,
      lead_provider:,
      school:,
      ukprn: school.ukprn,
      headteacher_status: "no",
      eligible_for_funding: true,
      funding_eligiblity_status_code: FundingEligibility::FUNDED_ELIGIBILITY_RESULT,
      funding_choice: "trust",
      ecf_id: "a6df7e0b-dff6-46c5-a5ea-9c1145cf96b7",
      teacher_catchment: new_teacher_catchment,
      teacher_catchment_country: new_teacher_catchment_country,
    )
  end

  let(:find_response_body) do
    {
      data: {
        type: "npq_profiles",
        id: "a6df7e0b-dff6-46c5-a5ea-9c1145cf96b7",
        attributes: {
          teacher_reference_number: "1234567",
          teacher_reference_number_verified: true,
          active_alert: true,
          date_of_birth: user.date_of_birth.iso8601,
          national_insurance_number: user.national_insurance_number,
          school_urn: application.school_urn,
          school_ukprn: application.ukprn,
          headteacher_status: "no",
          eligible_for_funding: false,
          funding_choice: "trust",
          teacher_catchment: old_teacher_catchment,
          teacher_catchment_country: old_teacher_catchment_country,
        },
      },
    }.to_json
  end

  let(:request_body) do
    {
      data: {
        id: "a6df7e0b-dff6-46c5-a5ea-9c1145cf96b7",
        type: "npq_profiles",
        attributes: {
          eligible_for_funding: true,
          funding_eligiblity_status_code: "funded",
          teacher_catchment: new_teacher_catchment,
          teacher_catchment_country: new_teacher_catchment_country,
        },
      },
    }.to_json
  end

  let(:response_body) do
    {
      data: {
        type: "npq_profiles",
        id: "a6df7e0b-dff6-46c5-a5ea-9c1145cf96b7",
      },
    }.to_json
  end

  before do
    stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-profiles/#{application.ecf_id}")
      .to_return(
        status: 200,
        body: find_response_body,
        headers: {
          "Content-Type" => "application/vnd.api+json",
        },
      )
  end

  it "calls ecf to update the eligible_for_funding attribute" do
    subject.call
    expect(update_ecf_stub).to have_been_requested
  end

  context "when ecf_api_disabled flag is toggled on" do
    before { allow(Rails.application.config).to receive(:npq_separation).and_return({ ecf_api_disabled: true }) }

    it "returns nil" do
      expect(subject.call).to be_nil
    end
  end
end
