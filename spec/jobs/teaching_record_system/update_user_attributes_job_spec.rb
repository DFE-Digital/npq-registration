require "rails_helper"

RSpec.describe TeachingRecordSystem::UpdateUserAttributesJob, type: :job do
  subject(:perform_job) { described_class.perform_now(user_id: user.id, access_token:) }

  before { allow(Sentry).to receive(:capture_exception) }

  let(:user) { create(:user, :with_teacher_auth, :with_verified_trn, :with_previous_names) }
  let(:access_token) { "a-token" }

  let :stub_person_request do
    stub_request(:get, "#{ENV['TRS_API_URL']}/v3/person")
      .with(
        headers: {
          "Authorization" => "Bearer #{access_token}",
          "X-Api-Version" => "Next",
        },
        query: { "include" => "PreviousNames" },
      )
  end

  let :person_api_response do
    {
      status: 200,
      body: { previousNames: api_previous_names }.to_json,
    }
  end

  let :api_previous_names do
    [{ "firstName" => "Sarah", "lastName" => "Johnson" }]
  end

  let(:stub_api) { stub_person_request.to_return(person_api_response) }

  context "when the user does not exist" do
    subject(:perform_job) { described_class.perform_now(user_id: 9999, access_token:) }

    it "notifies sentry but does not reschedule" do
      expect { perform_job }.not_to raise_exception

      expect(Sentry).to have_received(:capture_exception)
    end
  end

  context "when the user does not have a TRN" do
    let(:user) { create(:user, :with_teacher_auth, :without_trn) }

    it { expect { perform_job }.to(not_change { user.reload.previous_names }) }
  end

  context "when the API returns no previous names" do
    before { stub_person_request.to_return(person_api_response) }

    let(:api_previous_names) { [] }

    it "stores an empty array for previous_names on the user" do
      expect { perform_job }
        .to change { user.reload.previous_names }.to([])
    end
  end

  context "when the API returns one previous name" do
    before { stub_person_request.to_return(person_api_response) }

    it "stores the previous name on the user" do
      expect { perform_job }
        .to change { user.reload.previous_names }.to(["Sarah Johnson"])
    end
  end

  context "when the API returns multiple previous names" do
    before { stub_person_request.to_return(person_api_response) }

    let(:api_previous_names) do
      [
        { "firstName" => "Sarah", "lastName" => "Johnson" },
        { "firstName" => "Sarah", "middleName" => "Ann", "lastName" => "Williams" },
      ]
    end

    it "stores all previous_names on the user" do
      expect { perform_job }
        .to change { user.reload.previous_names }.to(["Sarah Johnson", "Sarah Ann Williams"])
    end
  end

  context "when the API is flaky" do
    before do
      stub_person_request
        .to_timeout
        .to_return(person_api_response)
    end

    it "replaces old previous_names with new API data" do
      expect { perform_job }
        .to change { user.reload.previous_names }
              .to(["Sarah Johnson"])
              .and(not_raise_exception)

      expect(Sentry).not_to have_received(:capture_exception)
    end
  end

  context "when API is timing out" do
    before do
      stub_person_request
        .to_timeout
        .to_timeout
    end

    it "does not change the users previous name or reschedule job" do
      expect { perform_job }
        .to not_change { user.reload.previous_names }
              .and(not_raise_exception)

      expect(Sentry).to have_received(:capture_exception)
    end
  end
end
