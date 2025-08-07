class Exporters::TadSencoDataRequest
  def initialize(cohort:, schedules:, file:)
    @cohort = cohort
    @schedules = schedules
    @file = file
    @csv = []
    @csv << csv_headers
  end

  def call
    generate_data
    save_data_to_csv
  end

  def applications
    course_id = Course.where(identifier: "npq-senco").pluck(:id)
    schedule_id = @schedules.pluck(:id)

    Application.where(schedule_id:, course_id:).includes(:user, :lead_provider, :school, :private_childcare_provider, :cohort, :declarations)
  end

private

  def generate_data
    applications.find_each(batch_size: 500) do |application|
      @csv << [
        application.training_status ? application.user.full_name : nil,
        application.training_status ? application.user.email : nil,
        application.id,
        application.ecf_id,
        application.user.id,
        application.user.ecf_id,
        application.user.trn_verified,
        application.lead_provider.id,
        application.lead_provider.ecf_id,
        application.employment_role,
        application.employment_type,
        application.work_setting,
        application.works_in_school,
        application&.school&.urn,
        application&.private_childcare_provider&.urn,
        application&.school&.number_of_pupils,
        application.eligible_for_funding,
        application.funding_choice,
        application.funded_place,
        application.senco_in_role,
        application.senco_start_date,
        started?(application),
        application.lead_provider_approval_status,
        application.training_status,
        application.headteacher_status,
        application.cohort.start_year,
      ]
    end
  end

  def started?(application)
    application.declarations.where(declaration_type: "started").any?
  end

  def save_data_to_csv
    @file.write(@csv.map(&:to_csv).join)
  end

  def csv_headers
    [
      "Full Name",
      "Email",
      "Application ID",
      "Application ECF ID",
      "User ID",
      "User ECF ID",
      "TRN Verified",
      "Lead Provider ID",
      "Lead Provider ECF ID",
      "Employment Role",
      "Employment Type",
      "Work Setting",
      "Works In School",
      "School URN",
      "Private Childcare Provider URN",
      "Number Of Pupils",
      "Eligible For Funding",
      "Funding Choice",
      "Funded Place",
      "Senco In Role",
      "Senco Start Date",
      "Started Course",
      "Lead Provider Approval Status",
      "Training Status",
      "Headteacher Status",
      "Cohort",
    ]
  end
end
