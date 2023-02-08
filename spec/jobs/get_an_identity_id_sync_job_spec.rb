require "rails_helper"

RSpec.describe GetAnIdentityIdSyncJob do
  subject { described_class.new(user:).perform_now }

  describe "#perform" do
    let(:get_an_identity_id) { SecureRandom.uuid }
    let(:ecf_id) { SecureRandom.uuid }
    let(:user) { create(:user, get_an_identity_id:, ecf_id:) }

    let(:existing_get_an_identity_id) { nil }

    let(:update_response_code) { 200 }
    let(:update_response_body) do
      {
        "data" => {
          "id" => ecf_id,
          "type" => "user",
          "attributes" => {
            "email" => user.email,
            "full_name" => user.full_name,
            "get_an_identity_id" => get_an_identity_id,
          },
        },
      }
    end

    before do
      stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq/users/#{user.ecf_id}")
        .with(
          headers: {
            "Authorization" => "Bearer ECFAPPBEARERTOKEN",
          },
        )
        .to_return(
          status: show_response_code,
          body: show_response_body.to_json,
          headers: {
            "Content-Type" => "application/vnd.api+json",
          },
        )

      stub_request(:patch, "https://ecf-app.gov.uk/api/v1/npq/users/#{user.ecf_id}")
        .with(
          headers: {
            "Authorization" => "Bearer ECFAPPBEARERTOKEN",
          },
          body: {
            data: {
              id: user.ecf_id,
              type: "user",
              attributes: {
                get_an_identity_id:,
              },
            },
          },
        ).to_return(
          status: update_response_code,
          body: update_response_body.to_json,
          headers: {
            "Content-Type" => "application/vnd.api+json",
          },
        )
    end

    context "when user exists on ECF" do
      let(:show_response_body) do
        {
          "data" => {
            "id" => ecf_id,
            "type" => "user",
            "attributes" => {
              "email" => user.email,
              "full_name" => user.full_name,
              "get_an_identity_id" => existing_get_an_identity_id,
            },
          },
        }
      end
      let(:show_response_code) { 200 }

      context "when user does not have a get_an_identity_id" do
        let(:get_an_identity_id) { nil }

        context "and there is not one on the ECF record" do
          let(:existing_get_an_identity_id) { nil }

          it "does not perform an update request" do
            subject

            expect(WebMock).not_to have_requested(:patch, "https://ecf-app.gov.uk/api/v1/npq/users/#{user.ecf_id}")
          end
        end
      end

      context "when user has a get_an_identity_id" do
        let(:get_an_identity_id) { SecureRandom.uuid }

        context "and there is not one on the ECF record" do
          let(:existing_get_an_identity_id) { nil }

          let(:update_response_code) { 200 }
          let(:update_response_body) do
            {
              "data" => {
                "id" => ecf_id,
                "type" => "user",
                "attributes" => {
                  "email" => user.email,
                  "full_name" => user.full_name,
                  "get_an_identity_id" => get_an_identity_id,
                },
              },
            }
          end

          it "performs an update request" do
            subject

            expect(WebMock).to have_requested(:patch, "https://ecf-app.gov.uk/api/v1/npq/users/#{user.ecf_id}")
          end

          context "and the get_an_identity_id is already taken on another record" do
            let(:update_response_code) { 400 }
            let(:update_response_body) do
              {
                errors: [
                  {
                    "title" => "get_an_identity_id",
                    "detail" => "has already been taken",
                  },
                ],
              }
            end

            it "performs an update request" do
              expect {
                subject
              }.to raise_error(JsonApiClient::Errors::ClientError)

              expect(WebMock).to have_requested(:patch, "https://ecf-app.gov.uk/api/v1/npq/users/#{user.ecf_id}")
            end

            it "stores a log of the failure" do
              expect {
                expect {
                  subject
                }.to change(EcfSyncRequestLog, :count).by(1)
              }.to raise_error(JsonApiClient::Errors::ClientError)
            end
          end
        end

        context "and there is one on the ECF record" do
          let(:get_an_identity_id) { SecureRandom.uuid }

          context "that does not match the one on the ECF record" do
            let(:existing_get_an_identity_id) { SecureRandom.uuid }

            let(:update_response_code) { 400 }
            let(:update_response_body) do
              {
                errors: [
                  {
                    "title" => "get_an_identity_id",
                    "detail" => "cannot be changed once set",
                  },
                ],
              }
            end

            it "performs an update request" do
              expect {
                subject
              }.to raise_error(JsonApiClient::Errors::ClientError)

              expect(WebMock).to have_requested(:patch, "https://ecf-app.gov.uk/api/v1/npq/users/#{user.ecf_id}")
            end

            it "stores a log of the failure" do
              expect {
                expect {
                  subject
                }.to change(EcfSyncRequestLog, :count).by(1)
              }.to raise_error(JsonApiClient::Errors::ClientError)
            end
          end

          context "that matches the one on the ECF record" do
            let(:existing_get_an_identity_id) { get_an_identity_id }

            it "does not perform an update request" do
              subject

              expect(WebMock).not_to have_requested(:patch, "https://ecf-app.gov.uk/api/v1/npq/users/#{user.ecf_id}")
            end
          end
        end
      end
    end

    context "when user does not existing on ECF" do
      let(:show_response_body) do
        { "error" => "User not found" }
      end
      let(:show_response_code) { 404 }

      it "stores a log of the failure" do
        expect {
          expect {
            subject
          }.to change(EcfSyncRequestLog, :count).by(1)
        }.to raise_error(JsonApiClient::Errors::NotFound)
      end
    end

    context "when request auth key is rejected" do
      let(:show_response_body) do
        {
          "error" => "HTTP Token: Access denied",
        }
      end
      let(:show_response_code) { 401 }

      it "stores a log of the failure" do
        expect {
          expect {
            subject
          }.to change(EcfSyncRequestLog, :count).by(1)
        }.to raise_error(JsonApiClient::Errors::NotAuthorized)
      end
    end
  end
end
