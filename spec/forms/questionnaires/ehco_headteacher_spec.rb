require "rails_helper"

RSpec.describe Questionnaires::EhcoHeadteacher, type: :model do
  it { is_expected.to validate_inclusion_of(:ehco_headteacher).in_array(Questionnaires::EhcoHeadteacher::VALID_EHCO_HEADTEACHER_OPTIONS) }
end
