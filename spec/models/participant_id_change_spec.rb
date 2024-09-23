# frozen_string_literal: true

require "rails_helper"

RSpec.describe ParticipantIdChange, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:from_participant_id) }
    it { is_expected.to validate_presence_of(:to_participant_id) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user).class_name("User") }
  end
end
