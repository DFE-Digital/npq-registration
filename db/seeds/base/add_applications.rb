# frozen_string_literal: true

LeadProvider.find_each do |lead_provider|
  quantity = { "review" => 4, "development" => 1 }.fetch(Rails.env, 0)

  quantity.times do
    # users with one application each
    FactoryBot.create_list(
      :application,
      5,
      :with_random_user,
      :with_random_work_setting,
      :with_participant_id_change,
      lead_provider:,
      course: Course.all.sample,
      lead_provider_approval_status: "pending",
      cohort: Cohort.all.sample,
    )

    # users with 4 applications each
    FactoryBot.create_list(
      :application,
      4,
      %i[accepted rejected].sample,
      :with_random_participant_outcome_state,
      :with_random_work_setting,
      user: FactoryBot.create(:user, :with_random_name),
      lead_provider:,
      course: Course.all.sample,
      cohort: Cohort.all.sample,
    )

    # users with one accepted application each
    FactoryBot.create_list(
      :application,
      2,
      :accepted,
      :with_random_user,
      :with_random_work_setting,
      lead_provider:,
      course: Course.all.sample,
      participant_outcome_state: "passed",
      cohort: Cohort.all.sample,
    )

    # users with one rejected application each
    FactoryBot.create_list(
      :application,
      2,
      :rejected,
      :with_random_user,
      :with_random_work_setting,
      lead_provider:,
      course: Course.all.sample,
      participant_outcome_state: "failed",
      cohort: Cohort.all.sample,
    )

    # users with one deferred application each
    FactoryBot.create_list(
      :application,
      2,
      :deferred,
      %i[accepted rejected].sample,
      :with_random_user,
      :with_random_work_setting,
      :with_random_participant_outcome_state,
      lead_provider:,
      course: Course.all.sample,
      cohort: Cohort.all.sample,
    )

    # users with one withdrawn application each
    FactoryBot.create_list(
      :application,
      2,
      :withdrawn,
      %i[accepted rejected].sample,
      :with_random_user,
      :with_random_work_setting,
      :with_random_participant_outcome_state,
      lead_provider:,
      course: Course.all.sample,
      cohort: Cohort.all.sample,
    )

    # users with one eligible for funded place application each (cohort funding_cap true)
    FactoryBot.create_list(
      :application,
      2,
      :eligible_for_funded_place,
      :with_random_user,
      :with_random_work_setting,
      :with_participant_id_change,
      lead_provider:,
      course: Course.all.sample,
      funded_place: Faker::Boolean.boolean(true_ratio: 0.6),
      cohort: Cohort.where(funding_cap: true).sample || Cohort.all.sample.tap do |c|
                c.funding_cap = true
                c.save!
              end,
    )

    # users with one not eligible for funded place application each (cohort funding_cap true)
    FactoryBot.create_list(
      :application,
      2,
      :accepted,
      :with_random_user,
      :with_random_work_setting,
      :with_participant_id_change,
      lead_provider:,
      course: Course.all.sample,
      funded_place: false,
      cohort: Cohort.where(funding_cap: true).sample || Cohort.all.sample.tap do |c|
                c.funding_cap = true
                c.save!
              end,
    )

    # users with one funded place nil application each (cohort funding_cap false)
    FactoryBot.create_list(
      :application,
      2,
      :accepted,
      :with_random_user,
      :with_random_work_setting,
      :with_random_eligible_for_funding,
      :with_participant_id_change,
      lead_provider:,
      course: Course.all.sample,
      cohort: Cohort.where(funding_cap: false).sample || Cohort.all.sample.tap do |c|
                c.funding_cap = false
                c.save!
              end,
    )
  end
end
