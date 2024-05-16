FactoryBot.define do
  factory :course do
    sequence(:name) { |n| "NPQ Course #{n}" }
    identifier { Course::IDENTIFIERS.sample }
    ecf_id { SecureRandom.uuid }

    initialize_with do
      Course.find_by(identifier:) || new(**attributes)
    end
  end
end
