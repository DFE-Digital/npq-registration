require "rails_helper"

RSpec.describe NullUser do
  describe "methods" do
    it { expect(NullUser.new).to be_null_user }
    it { expect(NullUser.new).not_to be_actual_user }
  end
end
