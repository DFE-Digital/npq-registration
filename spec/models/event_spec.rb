require "rails_helper"

RSpec.describe Event, type: :model do
  describe "relationships" do
    it { is_expected.to belong_to(:user).required(false) }
    it { is_expected.to belong_to(:application).required(false) }
    it { is_expected.to belong_to(:course).required(false) }
    it { is_expected.to belong_to(:lead_provider).required(false) }
    it { is_expected.to belong_to(:school).required(false) }
    it { is_expected.to belong_to(:statement).required(false) }
    it { is_expected.to belong_to(:statement_item).required(false) }
    it { is_expected.to belong_to(:declaration).required(false) }
  end

  describe "validation" do
    describe "importance" do
      it { is_expected.to validate_presence_of(:importance) }
      it { is_expected.to validate_numericality_of(:importance).is_in(1..10).only_integer }
    end

    describe "subject" do
      it { is_expected.to validate_presence_of(:subject) }
      it { is_expected.to validate_length_of(:subject).is_at_most(128) }
    end
  end
end
