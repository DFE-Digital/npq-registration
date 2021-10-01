require "rails_helper"

RSpec.describe Forms::AsoFundingNotAvailable, type: :model do
  it { is_expected.to validate_inclusion_of(:aso_funding).in_array(Forms::AsoFundingNotAvailable::VALID_ASO_FUNDING_OPTIONS) }
end
