FactoryBot.define do
  factory :registration_wizard, class: "Registration::Wizard" do
    initialize_with { new(current_step:, current_step_params:, state_store:) }
    to_create { self }

    transient do
      state { {} }
      current_user { nil }
      repository { build(:registration_repository, **state) }
    end

    current_step { :start }
    current_step_params { {} }
    state_store { build(:registration_state_store, current_user:, repository:) }

    trait :completed do
      current_step { :check_answers }
      repository { build(:registration_repository, :completed, **state) }
    end
  end

  factory :registration_state_store, class: "Registration::StateStore" do
    initialize_with { new(current_user:, repository:) }
    to_create { self }

    transient do
      state { {} }
    end

    current_user { nil }
    repository { build(:registration_repository, **state) }

    trait :completed do
      repository { build(:registration_repository, :completed, **state) }
    end
  end

  factory :registration_repository, class: "DfE::Wizard::Repository::InMemory" do
    initialize_with do
      new.tap do |repo|
        repo.write(**attributes.symbolize_keys) if attributes.any?
      end
    end

    to_create { self }

    trait :completed do
      transient do
        course { create(Course::IDENTIFIERS.first.to_sym) }
        school { create(:school, :funding_eligible_establishment_type_code, urn: "9876543") }
        lead_provider { LeadProvider.first }
        current_user { create(:user) }
      end

      started { true }
      course_start_date { "yes" }
    end
  end
end
