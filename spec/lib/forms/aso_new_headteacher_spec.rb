require "rails_helper"

RSpec.describe Forms::AsoNewHeadteacher, type: :model do
  it { is_expected.to validate_inclusion_of(:aso_new_headteacher).in_array(Forms::AsoNewHeadteacher::VALID_ASO_NEW_HEADTEACHER_OPTIONS) }
end
