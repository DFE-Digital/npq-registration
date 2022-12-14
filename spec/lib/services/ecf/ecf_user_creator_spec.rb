require "rails_helper"

RSpec.describe Services::Ecf::EcfUserCreator do
  let(:user) { User.create!(email: "john.doe@example.com", full_name: "John Doe") }

  subject { described_class.new(user:) }

  describe "#call" do
    let(:request_body) do
      {
        data: {
          type: "users",
          attributes: {
            email: "john.doe@example.com",
            full_name: "John Doe",
          },
        },
      }.to_json
    end

    before do
      stub_request(:post, "https://ecf-app.gov.uk/api/v1/users")
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

      it "sets user.ecf_id with returned guid" do
        expect {
          subject.call
        }.to change(user, :ecf_id).to("123")
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
          "sync_type" => "user_creation",
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
            "errors": error_array,
          }
        end

        let(:response_code) { 400 }

        it "does not set application.ecf_id " do
          expect {
            subject.call
          }.to_not change(user, :ecf_id)
        end

        it "creates a EcfSyncRequestLog with status :failed" do
          expect {
            subject.call
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
            "sync_type" => "user_creation",
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

      it "does not set application.ecf_id " do
        expect {
          subject.call
        }.to_not change(user, :ecf_id)
      end

      it "creates a EcfSyncRequestLog with status :failed" do
        expect {
          subject.call
        }.to change(EcfSyncRequestLog, :count).by(1)

        expect(
          EcfSyncRequestLog.last.slice(:syncable, :status, :error_messages, :response_body, :sync_type),
        ).to match(
          "syncable" => user,
          "status" => "failed",
          "error_messages" => ["JsonApiClient::Errors::NotAuthorized - JsonApiClient::Errors::NotAuthorized"],
          "response_body" => response_body,
          "sync_type" => "user_creation",
        )
      end
    end
  end
end
