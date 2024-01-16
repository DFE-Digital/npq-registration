require "rails_helper"

RSpec.describe ParticipantIdChange, type: :model do
  it { is_expected.to belong_to(:user).required }
  it { is_expected.to belong_to(:from_participant).class_name("User").required }
  it { is_expected.to belong_to(:to_participant).class_name("User").required }
end
