require "rails_helper"

RSpec.describe Migration::Ecf::LeadProviderAPIToken, type: :model do
  it { expect(described_class.new).not_to be_readonly }

  it "generates a hashed token that can be used" do
    unhashed_token = described_class.create_with_random_token!(lead_provider: create(:lead_provider))

    expect(
      described_class.find_by_unhashed_token(unhashed_token),
    ).to eql(described_class.order(:created_at).last)
  end
end
