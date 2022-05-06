require "rails_helper"

RSpec.describe Forms::KindOfNursery, type: :model do
  it "defines valid kinds of nursery" do
    expect(described_class::KIND_OF_NURSERY_OPTIONS).to eq(%w[
      local_authority_maintained_nursery
      preschool_class_as_part_of_school
      private_nursery
    ])
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:kind_of_nursery) }
    it { is_expected.to validate_inclusion_of(:kind_of_nursery).in_array(described_class::KIND_OF_NURSERY_OPTIONS) }
  end
end
