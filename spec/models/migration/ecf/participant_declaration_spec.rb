require "rails_helper"

RSpec.describe Migration::Ecf::ParticipantDeclaration, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:cpd_lead_provider) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:cohort) }
    it { is_expected.to belong_to(:superseded_by).class_name("Migration::Ecf::ParticipantDeclaration").optional }
    it { is_expected.to have_many(:declaration_states) }
    it { is_expected.to have_many(:supersedes).class_name("Migration::Ecf::ParticipantDeclaration").with_foreign_key(:superseded_by_id).inverse_of(:superseded_by) }
  end
end
