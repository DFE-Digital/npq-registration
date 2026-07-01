# frozen_string_literal: true

all_courses = Course.all.to_a
funded_cohorts = Cohort.capped_funding.or(Cohort.full_funding).to_a
multiplier = Rails.configuration.x.db_seeding_multiplier

LeadProvider.find_each do |lead_provider|
  quantity = { "review" => multiplier * 4, "development" => multiplier }.fetch(Rails.env, 0)

  quantity.times do
    # users with one application each
    5.times do
      user = FactoryBot.build(:user, :with_random_name)
      cohort = funded_cohorts.sample
      Application.create!(
        cohort:,
        course: all_courses.sample,
        funded_place: false,
        funding_choice: "school",
        lead_mentor: false,
        lead_provider:,
        lead_provider_approval_status: :pending,
        school: School.open.sample,
        teacher_catchment: "england",
        teacher_catchment_country: "United Kingdom of Great Britain and Northern Ireland",
        teacher_catchment_iso_country_code: "GBR",
        ukprn: rand(10_000_000..99_999_999).to_s,
        user:,
        work_setting: "a_school",
      )
    end

    # users with 3 applications each
    user = FactoryBot.create(:user, :with_random_name)
    cohort = funded_cohorts.sample

    Application.create!(
      cohort:,
      course: all_courses.sample,
      funded_place: cohort.capped_funding? ? false : nil,
      funding_choice: "school",
      lead_mentor: false,
      lead_provider:,
      lead_provider_approval_status: :accepted,
      participant_outcome_state: "passed",
      school: School.open.sample,
      teacher_catchment: "england",
      teacher_catchment_country: "United Kingdom of Great Britain and Northern Ireland",
      teacher_catchment_iso_country_code: "GBR",
      ukprn: rand(10_000_000..99_999_999).to_s,
      user:,
      work_setting: "a_school",
    )

    2.times do
      Application.create!(
        cohort:,
        course: all_courses.sample,
        funded_place: cohort.capped_funding? ? false : nil,
        funding_choice: "school",
        lead_mentor: false,
        lead_provider:,
        lead_provider_approval_status: :rejected,
        participant_outcome_state: "passed",
        school: School.open.sample,
        teacher_catchment: "england",
        teacher_catchment_country: "United Kingdom of Great Britain and Northern Ireland",
        teacher_catchment_iso_country_code: "GBR",
        ukprn: rand(10_000_000..99_999_999).to_s,
        user:,
        work_setting: "a_school",
      )
    end

    # users with one accepted application each
    2.times do
      Application.create!(
        cohort:,
        course: all_courses.sample,
        funded_place: cohort.capped_funding? ? false : nil,
        funding_choice: "school",
        lead_mentor: false,
        lead_provider:,
        lead_provider_approval_status: :accepted,
        participant_outcome_state: "passed",
        school: School.open.sample,
        teacher_catchment: "england",
        teacher_catchment_country: "United Kingdom of Great Britain and Northern Ireland",
        teacher_catchment_iso_country_code: "GBR",
        ukprn: rand(10_000_000..99_999_999).to_s,
        user: FactoryBot.build(:user),
        work_setting: "a_school",
      )
    end

    # users with one rejected application each
    2.times do
      Application.create!(
        cohort:,
        course: all_courses.sample,
        funded_place: cohort.capped_funding? ? false : nil,
        funding_choice: "school",
        lead_mentor: false,
        lead_provider:,
        lead_provider_approval_status: :rejected,
        participant_outcome_state: "failed",
        school: School.open.sample,
        teacher_catchment: "england",
        teacher_catchment_country: "United Kingdom of Great Britain and Northern Ireland",
        teacher_catchment_iso_country_code: "GBR",
        ukprn: rand(10_000_000..99_999_999).to_s,
        user: FactoryBot.build(:user),
        work_setting: "a_school",
      )
    end

    # users with one deferred application each
    2.times do
      application = Application.create!(
        cohort:,
        course: all_courses.sample,
        funded_place: cohort.capped_funding? ? false : nil,
        funding_choice: "school",
        lead_mentor: false,
        lead_provider:,
        lead_provider_approval_status: %i[accepted rejected].sample,
        participant_outcome_state: "failed",
        school: School.open.sample,
        teacher_catchment: "england",
        teacher_catchment_country: "United Kingdom of Great Britain and Northern Ireland",
        teacher_catchment_iso_country_code: "GBR",
        training_status: "deferred",
        ukprn: rand(10_000_000..99_999_999).to_s,
        user: FactoryBot.build(:user),
        work_setting: "a_school",
      )
      ApplicationState.create!(
        application:,
        lead_provider:,
        reason: "other",
        state: "deferred",
      )
    end

    # users with one withdrawn application each
    2.times do
      application = Application.create!(
        cohort:,
        course: all_courses.sample,
        funded_place: cohort.capped_funding? ? false : nil,
        funding_choice: "school",
        lead_mentor: false,
        lead_provider:,
        lead_provider_approval_status: %i[accepted rejected].sample,
        participant_outcome_state: "failed",
        school: School.open.sample,
        teacher_catchment: "england",
        teacher_catchment_country: "United Kingdom of Great Britain and Northern Ireland",
        teacher_catchment_iso_country_code: "GBR",
        training_status: "deferred",
        ukprn: rand(10_000_000..99_999_999).to_s,
        user: FactoryBot.build(:user),
        work_setting: "a_school",
      )
      ApplicationState.create!(
        application:,
        lead_provider:,
        reason: "other",
        state: "withdrawn",
      )
    end

    # users with one eligible for funded place application each (cohort funding_cap true)
    2.times do
      Application.create!(
        cohort: Cohort.where(funding: "capped").sample,
        course: all_courses.sample,
        eligible_for_funding: true,
        funded_place: [true, false].sample,
        funding_choice: "school",
        lead_mentor: false,
        lead_provider:,
        lead_provider_approval_status: :accepted,
        participant_outcome_state: "passed",
        school: School.open.sample,
        teacher_catchment: "england",
        teacher_catchment_country: "United Kingdom of Great Britain and Northern Ireland",
        teacher_catchment_iso_country_code: "GBR",
        training_status: "deferred",
        ukprn: rand(10_000_000..99_999_999).to_s,
        user: FactoryBot.build(:user),
        work_setting: "a_school",
      )
    end

    # users with one not eligible for funded place application each (cohort funding_cap true)
    2.times do
      Application.create!(
        cohort: Cohort.where(funding: "capped").sample,
        course: all_courses.sample,
        eligible_for_funding: true,
        funded_place: false,
        funding_choice: "school",
        lead_mentor: false,
        lead_provider:,
        lead_provider_approval_status: :accepted,
        participant_outcome_state: "passed",
        school: School.open.sample,
        teacher_catchment: "england",
        teacher_catchment_country: "United Kingdom of Great Britain and Northern Ireland",
        teacher_catchment_iso_country_code: "GBR",
        training_status: "deferred",
        ukprn: rand(10_000_000..99_999_999).to_s,
        user: FactoryBot.build(:user),
        work_setting: "a_school",
      )
    end

    # users with one funded place nil application each (cohort funding_cap false)
    2.times do
      Application.create!(
        cohort: Cohort.where(funding: "full").sample,
        course: all_courses.sample,
        eligible_for_funding: [true, false].sample,
        funded_place: nil,
        funding_choice: "school",
        lead_mentor: false,
        lead_provider:,
        lead_provider_approval_status: :accepted,
        school: School.open.sample,
        teacher_catchment: "england",
        teacher_catchment_country: "United Kingdom of Great Britain and Northern Ireland",
        teacher_catchment_iso_country_code: "GBR",
        training_status: "deferred",
        ukprn: rand(10_000_000..99_999_999).to_s,
        user: FactoryBot.build(:user),
        work_setting: "a_school",
      )
    end
  end
end

course = Course.find_by!(identifier: Course::IDENTIFIERS.first.to_sym)

# Make sure some applications will appear in the In Review list
[
  { employment_type: :hospital_school },
  { employment_type: :lead_mentor_for_accredited_itt_provider },
  { employment_type: :local_authority_supply_teacher },
  { employment_type: :local_authority_virtual_school },
  { employment_type: :young_offender_institution },
  { employment_type: :other },
  { referred_by_return_to_teaching_adviser: "yes" },
].each do |application_attrs|
  FactoryBot.create_list(:application, multiplier, :manual_review, **application_attrs.merge(course:))
end

# TODO: re-enable this - disabled to see if it helps with the performance of the seeding job
# Application.order(id: :desc).each.with_index do |a, i|
#   a.update!(created_at: i.days.ago)
# end
