require "rails_helper"

RSpec.describe Migration::Ecf::ParticipantOutcome::Npq, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:participant_declaration).class_name("Migration::Ecf::ParticipantDeclaration") }
  end
end
