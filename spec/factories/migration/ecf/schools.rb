FactoryBot.define do
  factory :ecf_school, class: "Migration::Ecf::School" do
    name { Faker::University.name }
    urn { Faker::Number.unique.decimal_part(digits: 7) }
    address_line1 { Faker::Address.street_address }
    postcode { Faker::Address.postcode }
  end
end
