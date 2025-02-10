FactoryBot.define do
  factory :delivery_partner do
    ecf_id { SecureRandom.uuid }
    sequence(:name) { |n| "Delivery Partner #{n}" }
  end
end
