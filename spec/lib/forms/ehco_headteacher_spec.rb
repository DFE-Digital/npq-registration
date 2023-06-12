require "rails_helper"

RSpec.describe Forms::EhcoHeadteacher, type: :model do
  it { is_expected.to validate_inclusion_of(:ehco_headteacher).in_array(Forms::EhcoHeadteacher::VALID_EHCO_HEADTEACHER_OPTIONS) }
end
