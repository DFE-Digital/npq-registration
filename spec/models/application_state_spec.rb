require "rails_helper"

RSpec.describe ApplicationState do
  describe "relationships" do
    it { is_expected.to belong_to(:application) }
    it { is_expected.to belong_to(:lead_provider).optional }
  end

  describe "enums" do
    it {
      expect(subject).to define_enum_for(:state).with_values(
        active: "active",
        deferred: "deferred",
        withdrawn: "withdrawn",
      ).backed_by_column_of_type(:enum)
    }
  end
end
