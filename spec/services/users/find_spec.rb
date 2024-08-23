require "rails_helper"

RSpec.describe Users::Find do
  before { create(:user) }

  describe "#all" do
    subject { Users::Find.new.all }

    it { is_expected.to match_array(User.all) }
  end

  describe "#by_id" do
    let(:user) { create(:user) }

    subject { Users::Find.new.by_id(user.id) }

    it { is_expected.to eq(user) }
  end
end
