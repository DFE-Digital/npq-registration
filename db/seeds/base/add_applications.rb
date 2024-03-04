school_settings = %w[a_school an_academy_trust a_16_to_19_educational_setting]

Application.create!(
  user: @single_app_user,
  ecf_id: SecureRandom.uuid,
  lead_provider: LeadProvider.last,
  course: Course.all.sample,
  work_setting: school_settings.sample,
  lead_provider_approval_status: "accepted",
  participant_outcome_state: "passed",
)

outcome_states = %w[passed failed]
approval_statuses = %w[accepted rejected]

15.times do
  Application.create!(
    user: @multiple_app_user,
    ecf_id: SecureRandom.uuid,
    lead_provider: LeadProvider.all.sample,
    course: Course.all.sample,
    work_setting: school_settings.sample,
    lead_provider_approval_status: approval_statuses.sample,
    participant_outcome_state: outcome_states.sample,
  )
end
