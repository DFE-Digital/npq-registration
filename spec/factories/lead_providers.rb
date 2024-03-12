FactoryBot.define do
  factory :lead_provider do
    name { LeadProvider::ALL_PROVIDERS.keys.sample }
    ecf_id { LeadProvider::ALL_PROVIDERS.values.sample }
    hint { Faker::Lorem.sentence }

    initialize_with do
      LeadProvider.find_by(name:) || new(**attributes)
    end
  end
end
