FactoryBot.define do
  factory :lead_provider do
    transient do
      delivery_partner { nil }
      delivery_partners { Array.wrap(delivery_partner) }
    end

    name { Faker::Company.unique.name }
    ecf_id { SecureRandom.uuid }
    hint { Faker::Lorem.sentence }

    after :create do |lead_provider, evaluator|
      partnerships = if evaluator.delivery_partners.is_a?(Hash)
                       evaluator.delivery_partners
                     elsif evaluator.delivery_partners&.any?
                       { create(:cohort, :current) => evaluator.delivery_partners }
                     else
                       {}
                     end

      partnerships.each do |cohort, delivery_partners|
        Array.wrap(delivery_partners).each do |delivery_partner|
          lead_provider.delivery_partnerships.create! delivery_partner:, cohort:
        end
      end
    end
  end
end
