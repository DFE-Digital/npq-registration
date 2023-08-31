require "rails_helper"
require "tempfile"

RSpec.describe Services::Importers::PopulateGetIdentityId do
  it "Updates the get_identity_id for the user" do
    user = create(:user)
    create(:application, user:, ecf_id: "the-id-in-ecf")

    described_class.new.import([{ id: "the-id-in-ecf", user_id: "get-an-id-" }])

    expect(user.reload.uid).to eq("get-an-id-")
  end

  it "Updates multiple users" do
    user1 = create(:user)
    user2 = create(:user)

    create(:application, user: user1, ecf_id: "the-id-in-ecf-1")
    create(:application, user: user2, ecf_id: "the-id-in-ecf-2")

    described_class.new.import([
      { id: "the-id-in-ecf-1", user_id: "get-an-id-1" },
      { id: "the-id-in-ecf-2", user_id: "get-an-id-2" },
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
    create(:application, user:, ecf_id: "the-id-in-ecf")
    logger = instance_spy(Logger)
    allow(Rails).to receive(:logger).and_return(logger)

    described_class.new.import([{ id: "the-id-in-ecf", user_id: "get-an-id-" }])

    expect(logger).to have_received(:info).with("User #{user.id} has been updated with get_identity_id get-an-id-")
  end
end
