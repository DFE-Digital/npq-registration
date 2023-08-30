require "rails_helper"
require "tempfile"

RSpec.describe Services::Importers::PopulateGetIdentityId do
  it "Updates the get_identity_id for the user" do
    user = create(:user)
    application = create(:application, user:)

    described_class.new.import([{ id: application.id, user_id: "get-an-id-" }])

    expect(user.reload.uid).to eq("get-an-id-")
  end

  it "Updates multiple users" do
    user1 = create(:user)
    user2 = create(:user)

    application1 = create(:application, user: user1)
    application2 = create(:application, user: user2)

    described_class.new.import([{ id: application1.id, user_id: "get-an-id-1" }, { id: application2.id, user_id: "get-an-id-2" }])

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
    application = create(:application, user:)
    logger = instance_spy(Logger)
    allow(Rails).to receive(:logger).and_return(logger)

    described_class.new.import([{ id: application.id, user_id: "get-an-id-" }])

    expect(logger).to have_received(:info).with("User #{user.id} has been updated with get_identity_id get-an-id-")
  end
end
