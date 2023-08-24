require "rails_helper"
require "tempfile"

RSpec.describe Services::Importers::PopulateGetIdentityId do
  it "Updates the get_identity_id for the user" do
    user = create(:user)

    described_class.new.import([{ id: "123", user_id: user.id }])

    expect(user.reload.uid).to eq("123")
  end
end
