require "rails_helper"

RSpec.describe Questionnaires::KindOfNursery, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:kind_of_nursery) }
    it { is_expected.to validate_inclusion_of(:kind_of_nursery).in_array(described_class::KIND_OF_NURSERY_OPTIONS) }
  end
end
