require "rails_helper"

RSpec.describe LocalAuthority do
  describe "#eligibility_lists" do
    subject { local_authority.eligibility_lists }

    let(:entry) { create(:eligibility_list_entry, :pp50_further_education, identifier:) }
    let(:identifier) { "12345678" }
    let(:local_authority) { create :local_authority, ukprn: entry.identifier }

    it { is_expected.to be_empty }
  end
end
