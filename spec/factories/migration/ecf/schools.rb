# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_school, class: "Migration::Ecf::School" do
    sequence(:name) { |n| "School #{n}" }
    urn { Faker::Number.unique.decimal_part(digits: 7) }
    address_line1 { Faker::Address.street_address }
    postcode { Faker::Address.postcode }

    trait :with_applications do
      after(:create) do |school|
        create_list(:ecf_migration_npq_application, 1, school_urn: school.urn, user: create(:ecf_migration_user))
      end
    end
  end
end
