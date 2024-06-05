# frozen_string_literal: true

LeadProvider.find_each do |lead_provider|
  quantity = { "review" => 4, "development" => 1 }.fetch(Rails.env, 0)

  quantity.times do
    # users with one application each
    FactoryBot.create_list(
      :application,
      10,
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
      :with_random_lead_provider_approval_status,
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
      4,
      :with_random_user,
      :with_random_work_setting,
      lead_provider:,
      course: Course.all.sample,
      lead_provider_approval_status: "accepted",
      participant_outcome_state: "passed",
      cohort: Cohort.all.sample,
    )

    # users with one rejected application each
    FactoryBot.create_list(
      :application,
      4,
      :with_random_user,
      :with_random_work_setting,
      lead_provider:,
      course: Course.all.sample,
      lead_provider_approval_status: "rejected",
      participant_outcome_state: "failed",
      cohort: Cohort.all.sample,
    )

    # users with one deferred application each
    FactoryBot.create_list(
      :application,
      4,
      :deferred,
      :with_random_user,
      :with_random_work_setting,
      :with_random_lead_provider_approval_status,
      :with_random_participant_outcome_state,
      lead_provider:,
      course: Course.all.sample,
      cohort: Cohort.all.sample,
    )

    # users with one withdrawn application each
    FactoryBot.create_list(
      :application,
      4,
      :withdrawn,
      :with_random_user,
      :with_random_work_setting,
      :with_random_lead_provider_approval_status,
      :with_random_participant_outcome_state,
      lead_provider:,
      course: Course.all.sample,
      cohort: Cohort.all.sample,
    )
  end
end
