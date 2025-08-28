class EylUsers3181
  include Rake::DSL

  FILENAME = "tmp/eyl_users.csv".freeze

  CSV_HEADERS = %w[
    full_name
    email
    application_id
    employment_role
    employment_type
    work_setting
    works_in_school
    school_urn
    private_childcare_provider_urn
    started_course_flag
    lead_provider_approval_status
    training_status
    cohort_start_year
  ].freeze

  def initialize
    namespace :one_off do
      desc "Export CSV of EYL users for ticket CPDNPQ-3181"
      task eyl_users: :environment do
        CSV.open(FILENAME, "w") do |csv|
          csv << CSV_HEADERS
          applications.each do |application|
            csv << [
              application.user.full_name,
              application.user.email,
              application.ecf_id,
              application.employment_role,
              application.employment_type,
              application.work_setting,
              application.works_in_school,
              application&.school&.urn,
              application&.private_childcare_provider&.provider_urn,
              started?(application),
              application.lead_provider_approval_status,
              application.training_status,
              application.cohort.start_year,
            ]
          end
        end
      end
    end
  end

private

  def applications
    Application.includes(:user, :school, :private_childcare_provider, :cohort, :declarations)
      .where(course_id: Course.npqeyl.id, training_status: ["active", nil])
  end

  def started?(application)
    !!application.declarations.find { |declaration| declaration.declaration_type == "started" }
  end
end
EylUsers3181.new
