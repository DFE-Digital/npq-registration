# frozen_string_literal: true

RSpec.shared_context "with eligibility list entries" do
  before do
    FactoryBot.create(:eligibility_list_entry, :pp50_school, identifier: "100000")
    FactoryBot.create(:eligibility_list_entry, :disadvantaged_early_years_school, identifier: "100000")
    FactoryBot.create(:eligibility_list_entry, :disadvantaged_early_years_school, identifier: "EY487263") # this is a "Ofsted URN"
  end
end

RSpec.configure do |config|
  config.include_context "with eligibility list entries", :with_eligibility_list_entries
end
