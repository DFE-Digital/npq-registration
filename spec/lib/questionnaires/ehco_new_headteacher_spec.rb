require "rails_helper"

RSpec.describe Questionnaires::EhcoNewHeadteacher, type: :model do
  it { is_expected.to validate_inclusion_of(:ehco_new_headteacher).in_array(Questionnaires::EhcoNewHeadteacher::VALID_EHCO_NEW_HEADTEACHER_OPTIONS) }
end
