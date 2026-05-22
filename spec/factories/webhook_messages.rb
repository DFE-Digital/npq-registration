FactoryBot.define do
  factory :get_an_identity_webhook_message, class: "GetAnIdentity::WebhookMessage" do
    transient do
      middle_name { nil }
      date_of_birth { "1995-01-01" }
    end

    message_id { SecureRandom.uuid }
    message_type { "UserUpdated" }
    status { "failed" }
    status_comment { "Invalid message format" }
    sent_at { Time.zone.now }
    processed_at { Time.zone.now }
    raw do
      {
        "message" => {
          "user" => {
            "trn" => "1234567",
            "userId" => SecureRandom.uuid,
            "lastName" => "Doe",
            "firstName" => "John",
            "middleName" => middle_name,
            "dateOfBirth" => date_of_birth,
            "emailAddress" => Faker::Internet.email(name: "John Doe"),
            "mobileNumber" => nil,
            "preferredName" => "John Doe",
            "trnLookupStatus" => "Pending",
          },
          "changes" => { "preferredName" => "John Doe" },
        },
        "timeUtc" => Time.zone.now.as_json,
        "messageType" => "UserUpdated",
        "notificationId" => SecureRandom.uuid,
      }
    end
    message { raw["message"] }
  end

  factory :trs_user_updated_webhook_message, class: "GetAnIdentity::WebhookMessage" do
    transient do
      user_email { "user@example.com" }
      user_trn { "0000000" }
    end
    message_id { SecureRandom.uuid }
    message_type { "alert.updated" }
    status { "pending" }
    sent_at { Time.zone.now }
    message do
      {
        "oneLoginUser" => {
          "subject" => "something",
          "emailAddress" => user_email,
        },
        "connectedPerson" => {
          "trn" => user_trn,
        },
      }
    end
  end

  factory :trs_trn_request_completed_webhook_message, class: "GetAnIdentity::WebhookMessage" do
    transient do
      user_uid { "urn:fdc:gov.uk:2022:#{SecureRandom.alphanumeric(43)}" }
      user_trn { "1234567" }
    end

    message_id { SecureRandom.uuid }
    message_type { "trn_request.completed" }
    status { "pending" }
    sent_at { Time.zone.now }
    message do
      {
        "trnRequest" => {
          "trn" => user_trn,
          "status" => "Completed",
          "potentialDuplicate" => true,
          "oneLoginUserSubject" => user_uid,
        },
      }
    end
  end
end
