require "rails_helper"

RSpec.describe EligibilityList, type: :model do
  let(:identifier) { "123" }

  describe "before_validation" do
    EligibilityList.descendants.each do |eligibility_list|
      context "with #{eligibility_list}" do
        it "sets the correct identifier type" do
          expect(eligibility_list.create!(identifier:).identifier_type).to eq(eligibility_list::IDENTIFIER_TYPE.to_s)
        end
      end
    end
  end
end
