require "rails_helper"

RSpec.describe Questionnaires::FundingYourEhco, type: :model do
  it { is_expected.to validate_inclusion_of(:ehco_funding_choice).in_array(Questionnaires::FundingYourEhco::VALID_FUNDING_OPTIONS) }
end
