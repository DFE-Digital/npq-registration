require "rails_helper"
require "tempfile"

RSpec.describe Importers::PopulateGetIdentityId do
  it "Updates the get_identity_id for the user" do
    user = create(:user)
    create(:application, user:, ecf_id: "ba752426-6029-429a-9b0b-40bcf51b8e8a")

    described_class.new.import([{ id: "ba752426-6029-429a-9b0b-40bcf51b8e8a", user_id: "get-an-id-" }])

    expect(user.reload.uid).to eq("get-an-id-")
    expect(user.reload.provider).to eq("tra_openid_connect")
  end

  it "Updates multiple users" do
    user1 = create(:user)
    user2 = create(:user)

    create(:application, user: user1, ecf_id: "6e46fc16-ecf6-4cff-9be7-88f0f02f1cb9")
    create(:application, user: user2, ecf_id: "4a55a113-e1c7-40dc-bde2-1a477fd91480")

    described_class.new.import([
      { id: "6e46fc16-ecf6-4cff-9be7-88f0f02f1cb9", user_id: "get-an-id-1" },
      { id: "4a55a113-e1c7-40dc-bde2-1a477fd91480", user_id: "get-an-id-2" },
    ])

    expect(user1.reload.uid).to eq("get-an-id-1")
    expect(user2.reload.uid).to eq("get-an-id-2")
  end

  it "Raises an error if the application does not exist" do
    expect {
      described_class.new.import([{ id: 999, user_id: "any-value" }])
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "Logs the uid to the Rails logger" do
    user = create(:user)
    create(:application, user:, ecf_id: "7359d562-f6c7-48d3-90e3-b90a928f6bcd")
    logger = instance_spy(Logger)
    allow(Rails).to receive(:logger).and_return(logger)

    described_class.new.import([{ id: "7359d562-f6c7-48d3-90e3-b90a928f6bcd", user_id: "get-an-id-" }])

    expect(logger).to have_received(:info).with("User #{user.id} has been updated with get_identity_id get-an-id-")
  end
end
