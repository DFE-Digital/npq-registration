require "rails_helper"

RSpec.describe Applications::Find do
  let!(:application) { FactoryBot.create(:application) }

  describe "#all" do
    it "includes both open and paid statements" do
      expect(Applications::Find.new.all).to include(application)
    end
  end
end
