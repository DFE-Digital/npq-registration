require "rails_helper"

RSpec.describe Event do
  describe "validation" do
    describe "title" do
      it { is_expected.to validate_presence_of(:title).with_message("Enter a title") }
      it { is_expected.to validate_length_of(:title).is_at_most(256).with_message("Title must be shorter than 256 characters") }
    end

    describe "event_type" do
      it { is_expected.to validate_presence_of(:event_type).with_message("Choose an event type") }
    end
  end

  describe "relationships" do
    it { is_expected.to belong_to(:admin).optional }
    it { is_expected.to belong_to(:application).optional }
    it { is_expected.to belong_to(:cohort).optional }
    it { is_expected.to belong_to(:course).optional }
    it { is_expected.to belong_to(:lead_provider).optional }
    it { is_expected.to belong_to(:private_childcare_provider).optional }
    it { is_expected.to belong_to(:school).optional }
    it { is_expected.to belong_to(:statement).optional }
    it { is_expected.to belong_to(:statement_item).optional }
    it { is_expected.to belong_to(:user).optional }
  end
end
