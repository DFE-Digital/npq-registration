require "rails_helper"

RSpec.describe Forms::FundingYourAso, type: :model do
  it { is_expected.to validate_inclusion_of(:aso_funding_choice).in_array(Forms::FundingYourAso::VALID_FUNDING_OPTIONS) }
end
