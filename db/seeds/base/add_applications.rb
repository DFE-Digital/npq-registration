# frozen_string_literal: true

all_courses = Course.all.to_a
all_cohorts = Cohort.all.to_a

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
      course: all_courses.sample,
      lead_provider_approval_status: "pending",
      cohort: all_cohorts.sample,
    )

    # users with 3 applications each
    user = FactoryBot.create(:user, :with_random_name)

    FactoryBot.create(
      :application,
      :accepted,
      :with_random_participant_outcome_state,
      :with_random_work_setting,
      user:,
      lead_provider:,
      course: all_courses.sample,
      cohort: all_cohorts.sample,
    )

    FactoryBot.create_list(
      :application,
      2,
      :rejected,
      :with_random_participant_outcome_state,
      :with_random_work_setting,
      user:,
      lead_provider:,
      course: all_courses.sample,
      cohort: all_cohorts.sample,
    )

    # users with one accepted application each
    FactoryBot.create_list(
      :application,
      2,
      :accepted,
      :with_random_user,
      :with_random_work_setting,
      lead_provider:,
      course: all_courses.sample,
      participant_outcome_state: "passed",
      cohort: all_cohorts.sample,
    )

    # users with one rejected application each
    FactoryBot.create_list(
      :application,
      2,
      :rejected,
      :with_random_user,
      :with_random_work_setting,
      lead_provider:,
      course: all_courses.sample,
      participant_outcome_state: "failed",
      cohort: all_cohorts.sample,
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
      course: all_courses.sample,
      cohort: all_cohorts.sample,
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
      course: all_courses.sample,
      cohort: all_cohorts.sample,
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
      course: all_courses.sample,
      funded_place: Faker::Boolean.boolean(true_ratio: 0.6),
      cohort: Cohort.where(funding_cap: true).sample || all_cohorts.sample.tap do |c|
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
      course: all_courses.sample,
      funded_place: false,
      cohort: Cohort.where(funding_cap: true).sample || all_cohorts.sample.tap do |c|
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
      :with_random_eligible_for_funding_seeds_only,
      :with_participant_id_change,
      lead_provider:,
      course: all_courses.sample,
      cohort: Cohort.where(funding_cap: false).sample || all_cohorts.sample.tap do |c|
                c.funding_cap = false
                c.save!
              end,
    )
  end
end

course = Course.find_by!(identifier: Course::IDENTIFIERS.first.to_sym)

# Make sure some applications will appear in the In Review list
[
  { employment_type: "hospital_school" },
  { employment_type: "lead_mentor_for_accredited_itt_provider" },
  { employment_type: "local_authority_supply_teacher" },
  { employment_type: "local_authority_virtual_school" },
  { employment_type: "young_offender_institution" },
  { employment_type: "other" },
  { referred_by_return_to_teaching_adviser: "yes" },
].each do |application_attrs|
  FactoryBot.create(:application, **application_attrs.merge(course:))
end

Application.order(id: :desc).each.with_index do |a, i|
  a.update!(created_at: i.days.ago)
end
