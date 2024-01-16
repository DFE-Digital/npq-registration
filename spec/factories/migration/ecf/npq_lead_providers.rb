FactoryBot.define do
  factory :ecf_npq_lead_provider, class: "Migration::Ecf::NpqLeadProvider" do
    sequence(:name) { |n| "Lead Provider #{n}" }
  end
end
