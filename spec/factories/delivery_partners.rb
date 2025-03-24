FactoryBot.define do
  factory :delivery_partner do
    transient do
      # either an array or a hash of cohort + array of lead providers
      lead_providers { Array.wrap(lead_provider) }
      lead_provider { nil }
    end

    ecf_id { SecureRandom.uuid }
    sequence(:name) { |n| "Delivery Partner #{n}" }

    after :create do |delivery_partner, evaluator|
      partnerships = if evaluator.lead_providers.is_a?(Hash)
                       evaluator.lead_providers
                     elsif evaluator.lead_providers&.any?
                       { create(:cohort, :current) => evaluator.lead_providers }
                     else
                       {}
                     end

      partnerships.each do |cohort, lead_providers|
        Array.wrap(lead_providers).each do |lead_provider|
          delivery_partner.delivery_partnerships.create! lead_provider:, cohort:
        end
      end
    end
  end
end
