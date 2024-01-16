FactoryBot.define do
  factory :ecf_npq_application, class: "Migration::Ecf::NpqApplication" do
    participant_identity { create(:ecf_participant_identity) }
    npq_course { create(:ecf_npq_course) }
    npq_lead_provider { create(:ecf_npq_lead_provider) }
    school_urn { Faker::Number.unique.decimal_part(digits: 7).to_s }
    school { create(:ecf_school, urn: school_urn) }
  end
end
