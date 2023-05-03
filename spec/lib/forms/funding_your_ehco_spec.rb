require "rails_helper"

RSpec.describe Forms::FundingYourEhco, type: :model do
  it { is_expected.to validate_inclusion_of(:ehco_funding_choice).in_array(Forms::FundingYourEhco::VALID_FUNDING_OPTIONS) }
end
