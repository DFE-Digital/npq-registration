class Exporters::TadDataRequest
  def initialize(cohort:, schedules:, courses:, file:)
    @cohort = cohort
    @schedules = schedules
    @courses = courses
    @file = file
    @csv = []
    @csv << csv_headers
  end

  def call
    generate_data
    save_data_to_csv
  end

  def applications
    course_id = @courses.pluck(:id)
    schedule_id = @schedules.pluck(:id)

    accepted_applications_ids = Declaration.billable.where(declaration_type: "started").where(cohort: @cohort).pluck(:application_id)
    Application.where(id: accepted_applications_ids, schedule_id:, course_id:)
  end

private

  def generate_data
    applications.each do |application|
      user = application.user
      school = application.school
      lead_provider = application.lead_provider
      course = application.course
      schedule = application.schedule
      cohort = application.cohort
      outcomes = application.declarations.map { |declaration|
        declaration.participant_outcomes.map do |outcome|
          [outcome.state, outcome.created_at]
        end
      }.flatten

      @csv << [
        user&.full_name,
        user&.email,
        user&.id,
        user&.trn,
        school&.urn,
        lead_provider&.name,
        course&.name,
        schedule&.name,
        cohort&.start_year,
        application.eligible_for_funding,
        application.training_status,
        application.targeted_support_funding_eligibility,
        application.targeted_delivery_funding_eligibility,
      ] + outcomes
    end
  end

  def save_data_to_csv
    @file.write(@csv.map(&:to_csv).join)
  end

  def csv_headers
    [
      "Full Name",
      "Email",
      "User ID",
      "Teacher Reference Number",
      "School URN",
      "Lead Provider Name",
      "Course Name",
      "Schedule",
      "Cohort Start Year",
      "Eligible for Funding",
      "Participant Status",
      "Targeted Support Funding Eligibility",
      "Targeted Delivery Funding Eligibility",
      "Outcome 1",
      "Outcome 1 Date",
      "Outcome 2",
      "Outcome 1 Date",
      "Outcome 3",
      "Outcome 3 Date",
      "Outcome 4",
      "Outcome 4 Date",
    ]
  end

  def cohort_id
    cohort = @schedules.map(&:cohort).uniq
    raise RuntimeError if cohort.size != 1

    cohort.first.id
  end
end
