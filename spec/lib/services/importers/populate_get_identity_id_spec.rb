require "rails_helper"
require "tempfile"

RSpec.describe Services::Importers::PopulateGetIdentityId do
  it "Updates the get_identity_id for the user" do
    user = create(:user)

    described_class.new.import([{ id: "123", user_id: user.id }])

    expect(user.reload.uid).to eq("123")
  end

  it "Updates multiple users" do
    user1 = create(:user)
    user2 = create(:user)

    described_class.new.import([{ id: "123", user_id: user1.id }, { id: "456", user_id: user2.id }])

    expect(user1.reload.uid).to eq("123")
    expect(user2.reload.uid).to eq("456")
  end

  it "Raises an error if the user does not exist" do
    expect {
      described_class.new.import([{ id: "123", user_id: 999 }])
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "Logs the uid to the Rails logger" do
    user = create(:user)
    logger = instance_spy(Logger)
    allow(Rails).to receive(:logger).and_return(logger)

    described_class.new.import([{ id: "123", user_id: user.id }])

    expect(logger).to have_received(:info).with("User #{user.id} has been updated with get_identity_id 123")
  end

  describe "Syncing to ECF" do
    it "Updates the get_identity_id for the ECF user" do
      user = create(:user, ecf_id: SecureRandom.uuid)
      ecf_user = instance_spy(EcfApi::Npq::User)

      allow_any_instance_of(User).to receive(:ecf_user).and_return(ecf_user)
      expect(ecf_user).to receive(:update!).with(get_identity_id: "123")

      described_class.new.import([{ id: "123", user_id: user.id }])
    end

    it "Logs an error if user is not synched with ECF" do
      user = create(:user, ecf_id: nil)
      logger = instance_spy(Logger)
      allow(Rails).to receive(:logger).and_return(logger)

      described_class.new.import([{ id: "123", user_id: user.id }])

      expect(logger).to have_received(:error).with("User #{user.id} get_identity_id has not been synced to ECF")
    end
  end
end
