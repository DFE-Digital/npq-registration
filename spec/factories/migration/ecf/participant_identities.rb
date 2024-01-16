FactoryBot.define do
  factory :ecf_participant_identity, class: "Migration::Ecf::ParticipantIdentity" do
    user { create(:ecf_user) }
    email { user.email }
    external_identifier { SecureRandom.uuid }
  end
end
