require "rails_helper"

RSpec.describe Services::NpqProfileCreator do
  let(:user) do
    User.create!(
      email: "john.doe@example.com",
      full_name: "John Doe",
      ecf_id: "123",
      trn: "1234567",
      trn_verified: true,
      active_alert: true,
      date_of_birth: Date.new(1980, 12, 13),
    )
  end
  let(:course) { Course.create!(name: "Some course", ecf_id: "234") }
  let(:lead_provider) { LeadProvider.create!(name: "Some lead provider", ecf_id: "345") }

  let(:application) do
    Application.create!(
      user: user,
      course: course,
      lead_provider: lead_provider,
      school_urn: "654321",
      headteacher_status: "no",
      eligible_for_funding: true,
      funding_choice: "trust",
    )
  end

  subject { described_class.new(application: application) }

  describe "#call" do
    let(:request_body) do
      {
        data: {
          type: "npq_profiles",
          relationships: {
            user: {
              data: {
                type: "users",
                id: "123",
              },
            },
            npq_course: {
              data: {
                type: "npq_courses",
                id: application.course.ecf_id,
              },
            },
            npq_lead_provider: {
              data: {
                type: "npq_lead_providers",
                id: application.lead_provider.ecf_id,
              },
            },
          },
          attributes: {
            teacher_reference_number: "1234567",
            teacher_reference_number_verified: true,
            active_alert: true,
            date_of_birth: user.date_of_birth.iso8601,
            school_urn: application.school_urn,
            headteacher_status: "no",
            eligible_for_funding: true,
            funding_choice: "trust",
          },
        },
      }.to_json
    end

    let(:response_body) do
      {
        data: {
          type: "npq_profiles",
          id: "789",
        },
      }.to_json
    end

    before do
      stub_request(:post, "https://ecf-app.gov.uk/api/v1/npq-profiles")
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

    it "sets application.ecf_id with returned guid" do
      subject.call
      expect(application.ecf_id).to eql("789")
    end
  end
end
