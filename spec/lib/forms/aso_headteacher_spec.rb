require "rails_helper"

RSpec.describe Forms::AsoHeadteacher, type: :model do
  it { is_expected.to validate_inclusion_of(:aso_headteacher).in_array(Forms::AsoHeadteacher::VALID_ASO_HEADTEACHER_OPTIONS) }
end
