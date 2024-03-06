require "rails_helper"

RSpec.describe Statements::Find do
  let!(:open_statement) { FactoryBot.create(:statement, :open) }
  let!(:paid_statement) { FactoryBot.create(:statement, :paid) }
  let!(:payable_statement) { FactoryBot.create(:statement, :payable) }

  describe "#all" do
    it "includes both open and paid statements" do
      expect(Statements::Find.new.all).to include(open_statement, paid_statement)
    end
  end

  describe "#paid" do
    it "includes paid statements" do
      expect(Statements::Find.new.paid).to include(paid_statement)
    end

    it "doesn't include open or payable statements" do
      expect(Statements::Find.new.paid).not_to include(open_statement)
      expect(Statements::Find.new.paid).not_to include(payable_statement)
    end
  end

  describe "#unpaid" do
    it "includes open and payable statements" do
      expect(Statements::Find.new.unpaid).to include(open_statement)
      expect(Statements::Find.new.unpaid).to include(payable_statement)
    end

    it "doesn't include paid statements" do
      expect(Statements::Find.new.unpaid).not_to include(paid_statement)
    end
  end
end
