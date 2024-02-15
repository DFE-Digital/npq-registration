FactoryBot.define do
  factory :admin do
    full_name { "John Doe" }
    sequence(:email) { |n| "admin#{n}@example.com" }
  end

  factory :super_admin, class: "Admin" do
    full_name { "Super Doe" }
    sequence(:email) { |n| "superadmin#{n}@example.com" }
    super_admin { true }
  end
end
