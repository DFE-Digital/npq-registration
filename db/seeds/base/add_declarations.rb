# frozen_string_literal: true

LeadProvider.find_each do |lead_provider|
  quantity = { "review" => 4, "development" => 1 }.fetch(Rails.env, 0)

  quantity.times do
    # Application with a started declaration
    application1 = FactoryBot.create(
      :application,
      :eligible_for_funded_place,
      :with_random_user,
      :with_random_work_setting,
      lead_provider:,
      course: Course.all.sample,
      cohort: Cohort.all.sample,
    )
    %w[started].each do |declaration_type|
      FactoryBot.create(
        :declaration,
        :submitted_or_eligible,
        application: application1,
        declaration_type:,
      )
    end

    # Application with a started and retained-1 declaration
    application2 = FactoryBot.create(
      :application,
      :eligible_for_funded_place,
      :with_random_user,
      :with_random_work_setting,
      lead_provider:,
      course: Course.all.sample,
      cohort: Cohort.all.sample,
    )
    %w[started retained-1].each do |declaration_type|
      FactoryBot.create(
        :declaration,
        :submitted_or_eligible,
        application: application2,
        declaration_type:,
      )
    end

    # Application with a started, retained-1 and retained-2 declaration
    application3 = FactoryBot.create(
      :application,
      :eligible_for_funded_place,
      :with_random_user,
      :with_random_work_setting,
      lead_provider:,
      course: Course.all.sample,
      cohort: Cohort.all.sample,
    )
    %w[started retained-1 retained-2].each do |declaration_type|
      FactoryBot.create(
        :declaration,
        :submitted_or_eligible,
        application: application3,
        declaration_type:,
      )
    end

    # Application with a started, retained-1, retained-2 and completed declaration
    application4 = FactoryBot.create(
      :application,
      :eligible_for_funded_place,
      :with_random_user,
      :with_random_work_setting,
      lead_provider:,
      course: Course.all.sample,
      cohort: Cohort.all.sample,
    )
    %w[started retained-1 retained-2 completed].each do |declaration_type|
      declaration = FactoryBot.create(
        :declaration,
        :submitted_or_eligible,
        application: application4,
        declaration_type:,
      )

      next unless declaration_type == "completed"

      ParticipantOutcomes::Create::STATES.reverse.each do |state|
        FactoryBot.create(:participant_outcome,
                          declaration:,
                          state:,
                          completion_date: declaration.declaration_date.to_s)

        break if Faker::Boolean.boolean(true_ratio: 0.3)
      end
    end
  end
end
