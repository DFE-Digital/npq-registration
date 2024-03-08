# users with one application each
FactoryBot.create_list(
  :application,
  20,
  :with_random_user,
  :with_random_work_setting,
  ecf_id: SecureRandom.uuid,
  lead_provider: LeadProvider.last,
  course: Course.all.sample,
  lead_provider_approval_status: "accepted",
  participant_outcome_state: "passed",
)

# a user with 4 applications
FactoryBot.create_list(
  :application,
  4,
  :with_random_lead_provider_approval_status,
  :with_random_participant_outcome_state,
  :with_random_work_setting,
  user: FactoryBot.create(:user, :with_random_name),
  ecf_id: SecureRandom.uuid,
  lead_provider: LeadProvider.all.sample,
  course: Course.all.sample,
)
