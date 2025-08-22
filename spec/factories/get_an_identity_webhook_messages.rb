FactoryBot.define do
  factory :get_an_identity_webhook_message, class: "GetAnIdentity::WebhookMessage" do
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
            "middleName" => nil,
            "dateOfBirth" => "1995-01-01",
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
end
