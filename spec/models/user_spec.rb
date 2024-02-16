require "rails_helper"

RSpec.describe User do
  describe "relationships" do
    it { is_expected.to belong_to(:applications) }
    it { is_expected.to have_many(:ecf_sync_request_logs).dependent(:destroy) }
  end
end
