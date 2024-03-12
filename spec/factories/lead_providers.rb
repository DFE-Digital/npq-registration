FactoryBot.define do
  factory :lead_provider do
    name { Faker::Company.unique.name }
    ecf_id { Faker::Alphanumeric.alphanumeric(number: 10) }
    hint { Faker::Lorem.sentence }
  end
end
