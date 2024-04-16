require "rails_helper"

RSpec.describe Migration::Ecf::School, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:npq_applications).class_name("NpqApplication").with_foreign_key(:school_urn).with_primary_key(:urn) }
  end
end
