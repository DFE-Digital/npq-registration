FactoryBot.define do
  factory :event do
    sequence(:title) { |n| "Event #{n}" }
    sequence(:description) { |n| "Event #{n} description goes here" }
    created_at { Time.zone.now }

    trait(:with_random_description) { description { Faker::Lorem.paragraph } }
    trait(:with_byline) { byline { Faker::Name.name } }
  end
end
