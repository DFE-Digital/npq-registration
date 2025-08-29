require "rails_helper"

RSpec.describe "one_off:eyl_users" do
  subject(:run_task) { Rake::Task["one_off:eyl_users"].invoke }

  before do
    create(:declaration, user: user_with_eyl_course, application:, course:)
    create(:declaration, user: user_with_eyl_course, application: application_2, course:)
    create(:declaration, user: user_with_eyl_deferred, application: application_deferred, course:)
    create(:declaration, user: user_with_eyl_withdrawn, application: application_withdrawn, course:)
    create(:declaration, user: user_with_other_course, application: application_other_course, course: other_course)
    stub_const("EylUsers3181::FILENAME", file.path)
  end

  after { file.unlink }

  let(:file) { Tempfile.new }
  let(:course) { create(:course, :early_years_leadership) }
  let(:other_course) { create(:course, :senior_leadership) }
  let(:user_with_eyl_course) { create(:user) }
  let(:user_2_with_eyl_course) { create(:user) }
  let(:application) { create(:application, :accepted, user: user_with_eyl_course, course:, employment_role: "something", employment_type: "hospital_school", work_setting: "a_school") }
  let(:application_2) { create(:application, :with_private_childcare_provider, user: user_with_eyl_course, course:) }
  let(:user_with_eyl_deferred) { create(:user) }
  let(:application_deferred) { create(:application, :deferred, user: user_with_eyl_deferred, course:) }
  let(:user_with_eyl_withdrawn) { create(:user) }
  let(:application_withdrawn) { create(:application, :withdrawn, user: user_with_eyl_withdrawn, course:) }
  let(:user_with_other_course) { create(:user) }
  let(:application_other_course) { create(:application, :accepted, user: user_with_other_course, course: other_course) }
  let!(:application_no_declarations) { create(:application, :accepted, user: user_2_with_eyl_course, course:) }

  let(:expected_data_for_application) do
    [
      user_with_eyl_course.full_name,
      user_with_eyl_course.email,
      application.ecf_id,
      application.employment_role,
      application.employment_type,
      application.work_setting,
      application.works_in_school,
      application&.school&.urn,
      application&.private_childcare_provider&.urn,
      true,
      application.lead_provider_approval_status,
      application.training_status,
      application.cohort.start_year,
    ]
  end

  let(:expected_data_for_application_2) do
    [
      user_with_eyl_course.full_name,
      user_with_eyl_course.email,
      application_2.ecf_id,
      application_2.employment_role,
      application_2.employment_type,
      application_2.work_setting,
      application_2.works_in_school,
      application_2&.school&.urn,
      application_2&.private_childcare_provider&.urn,
      true,
      application_2.lead_provider_approval_status,
      application_2.training_status,
      application_2.cohort.start_year,
    ]
  end

  let(:expected_data_for_application_with_no_declarations) do
    [
      user_2_with_eyl_course.full_name,
      user_2_with_eyl_course.email,
      application_no_declarations.ecf_id,
      application_no_declarations.employment_role,
      application_no_declarations.employment_type,
      application_no_declarations.work_setting,
      application_no_declarations.works_in_school,
      application_no_declarations&.school&.urn,
      application_no_declarations&.private_childcare_provider&.urn,
      false,
      application_no_declarations.lead_provider_approval_status,
      application_no_declarations.training_status,
      application_no_declarations.cohort.start_year,
    ]
  end

  let(:expected_csv) do
    CSV.generate_lines(
      [
        EylUsers3181::CSV_HEADERS,
        expected_data_for_application,
        expected_data_for_application_2,
        expected_data_for_application_with_no_declarations,
      ],
    )
  end

  let(:actual_csv) { File.read(EylUsers3181::FILENAME) }

  it "creates a CSV file with EYL users" do
    run_task
    expect(actual_csv).to eq(expected_csv)
  end
end
