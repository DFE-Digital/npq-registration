require "rails_helper"

RSpec.describe Services::Ecf::EcfUserUpdater do
  let(:old_get_an_identity_id) { SecureRandom.uuid }
  let(:new_get_an_identity_id) { SecureRandom.uuid }
  let(:ecf_id) { SecureRandom.uuid }
  let(:user) do
    User.create!(
      email: "rose.doe@example.com",
      full_name: "Rose Doe",
      uid: new_get_an_identity_id,
      provider: :tra_openid_connect,
      ecf_id:,
    )
  end

  subject { described_class.new(user:) }

  describe "#call" do
    let(:get_body) do
      {
        data: {
          type: "users",
          id: ecf_id,
          attributes: {
            email: "alice.doe@example.com",
            get_an_identity_id: old_get_an_identity_id,
            full_name: "Alice Doe",
          },
        },
      }
    end
    let(:get_response_code) { 200 }

    let(:request_body) do
      {
        data: {
          id: ecf_id,
          type: "users",
          attributes: {
            email: "rose.doe@example.com",
            full_name: "Rose Doe",
            get_an_identity_id: new_get_an_identity_id,
          },
        },
      }.to_json
    end

    before do
      stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq/users/#{ecf_id}")
        .to_return(
          status: get_response_code,
          body: get_body.to_json,
          headers: {
            "Content-Type" => "application/vnd.api+json",
          },
        )

      stub_request(:patch, "https://ecf-app.gov.uk/api/v1/npq/users/#{ecf_id}")
        .with(
          body: request_body,
          headers: {
            "Accept" => "application/vnd.api+json",
            "Authorization" => "Bearer ECFAPPBEARERTOKEN",
            "Content-Type" => "application/vnd.api+json",
          },
        )
        .to_return(
          status: response_code,
          body: response_body.to_json,
          headers: {
            "Content-Type" => "application/vnd.api+json",
          },
        )
    end

    context "when authorized" do
      let(:response_code) { 201 }
      let(:response_body) do
        {
          data: {
            type: "user",
            id: "123",
          },
        }
      end

      it "updates the user" do
        subject.call
        expect(a_request(:patch, "https://ecf-app.gov.uk/api/v1/npq/users/#{ecf_id}")).to have_been_made.once
      end

      it "creates a EcfSyncRequestLog with status :success" do
        expect {
          subject.call
        }.to change(EcfSyncRequestLog, :count).by(1)

        expect(
          EcfSyncRequestLog.last.slice(:syncable, :status, :error_messages, :response_body, :sync_type),
        ).to match(
          "syncable" => user,
          "status" => "success",
          "error_messages" => [],
          "response_body" => nil,
          "sync_type" => "user_update",
        )
      end

      context "when save fails" do
        let(:error_array) do
          [
            {
              "title" => "Invalid action",
              "detail" => "Validation failed: Email Enter an email address in the correct format, like name@example.com",
            },
          ]
        end

        let(:response_body) do
          {
            "errors" => error_array,
          }
        end

        let(:response_code) { 400 }

        it "raises an error" do
          expect {
            subject.call
          }.to raise_error(JsonApiClient::Errors::ClientError)
        end

        it "does not set application.ecf_id " do
          expect {
            begin; subject.call; rescue StandardError; end # rubocop:disable Lint/SuppressedException
          }.to_not change(user, :ecf_id)
        end

        it "creates a EcfSyncRequestLog with status :failed" do
          expect {
            begin; subject.call; rescue StandardError; end # rubocop:disable Lint/SuppressedException
          }.to change(EcfSyncRequestLog, :count).by(1)

          expect(
            EcfSyncRequestLog.last.slice(:syncable, :status, :error_messages, :response_body, :sync_type),
          ).to match(
            "syncable" => user,
            "status" => "failed",
            "error_messages" => [
              "JsonApiClient::Errors::ClientError - Invalid action",
            ],
            "response_body" => response_body,
            "sync_type" => "user_update",
          )
        end
      end

      context "when user lookup fails" do
        let(:get_body) do
          {}
        end
        let(:get_response_code) { 404 }

        it "raises an error" do
          expect {
            subject.call
          }.to raise_error(JsonApiClient::Errors::NotFound)
        end

        it "does not set application.ecf_id " do
          expect {
            begin; subject.call; rescue StandardError; end # rubocop:disable Lint/SuppressedException
          }.to_not change(user, :ecf_id)
        end

        it "creates a EcfSyncRequestLog with status :failed" do
          expect {
            begin; subject.call; rescue StandardError; end # rubocop:disable Lint/SuppressedException
          }.to change(EcfSyncRequestLog, :count).by(1)

          expect(
            EcfSyncRequestLog.last.slice(:syncable, :status, :error_messages, :response_body, :sync_type),
          ).to match(
            "syncable" => user,
            "status" => "failed",
            "error_messages" => [
              "JsonApiClient::Errors::NotFound - Resource not found: https://ecf-app.gov.uk/api/v1/npq/users/#{ecf_id}",
            ],
            "response_body" => nil,
            "sync_type" => "user_update",
          )
        end
      end
    end

    context "when unauthorized" do
      let(:response_code) { 401 }

      let(:response_body) do
        {
          "error" => "HTTP Token: Access denied",
        }
      end

      it "raises an error" do
        expect {
          subject.call
        }.to raise_error(JsonApiClient::Errors::ClientError)
      end

      it "does not set application.ecf_id " do
        expect {
          begin; subject.call; rescue StandardError; end # rubocop:disable Lint/SuppressedException
        }.to_not change(user, :ecf_id)
      end

      it "creates a EcfSyncRequestLog with status :failed" do
        expect {
          begin; subject.call; rescue StandardError; end # rubocop:disable Lint/SuppressedException
        }.to change(EcfSyncRequestLog, :count).by(1)

        expect(
          EcfSyncRequestLog.last.slice(:syncable, :status, :error_messages, :response_body, :sync_type),
        ).to match(
          "syncable" => user,
          "status" => "failed",
          "error_messages" => ["JsonApiClient::Errors::NotAuthorized - JsonApiClient::Errors::NotAuthorized"],
          "response_body" => response_body,
          "sync_type" => "user_update",
        )
      end
    end
  end
end
