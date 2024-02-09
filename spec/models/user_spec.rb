require "rails_helper"

RSpec.describe(User, type: :model) do
  describe "relationships" do
    it { is_expected.to have_many(:events) }
  end
end
