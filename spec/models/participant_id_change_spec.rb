# frozen_string_literal: true

require "rails_helper"

RSpec.describe ParticipantIdChange, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:from_participant) }
    it { is_expected.to validate_presence_of(:to_participant) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user).class_name("User") }
    it { is_expected.to belong_to(:from_participant).class_name("User").with_primary_key("ecf_id") }
    it { is_expected.to belong_to(:to_participant).class_name("User").with_primary_key("ecf_id") }
  end
end
