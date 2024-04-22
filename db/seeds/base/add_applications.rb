# frozen_string_literal: true

LeadProvider.find_each do |lead_provider|
  [1, 2, 3, 4].each do
    # users with one application each
    FactoryBot.create_list(
      :application,
      10,
      :with_random_user,
      :with_random_work_setting,
      ecf_id: SecureRandom.uuid,
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
      ecf_id: SecureRandom.uuid,
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
      ecf_id: SecureRandom.uuid,
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
      ecf_id: SecureRandom.uuid,
      lead_provider:,
      course: Course.all.sample,
      lead_provider_approval_status: "rejected",
      participant_outcome_state: "passed",
      cohort: Cohort.all.sample,
    )
  end
end
