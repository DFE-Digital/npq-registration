require "rails_helper"

RSpec.describe Exporters::TadSencoDataRequest do
  let(:file) { Tempfile.new }
  let(:course) { create(:course, :senco) }
  let(:cohort) { create(:cohort, start_year: 2024) }
  let(:schedule) { create(:schedule, cohort: cohort, course_group: course.course_group, name: "Schedule Autumn 2024") }
  let(:user) { create(:user, full_name: "John Doe", email: "john@example.com") }

  let(:application) do
    create(
      :application,
      :accepted,
      :eligible_for_funding,
      user:,
      course:,
      schedule:,
      cohort:,
    )
  end

  let(:non_senco_application) do
    create(
      :application,
      :accepted,
      :eligible_for_funding,
      user:,
      course: create(:course, :senior_leadership),
      cohort:,
      schedule:,
    )
  end

  before do
    application
    non_senco_application
  end

  subject do
    described_class.new(cohort: cohort, schedules: [schedule], file: file)
  end

  describe "#applications" do
    it "selects applications" do
      expect(subject.applications.count).to eq(1)

      application = subject.applications.first
      expect(application.user).to eq(user)
    end
  end

  describe "#call" do
    let(:headers) do
      [
        "Full Name",
        "Email",
        "Application ID",
        "Application ECF ID",
        "User ID",
        "User ECF ID",
        "TRN",
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
    let(:expected_data) do
      [
        expected_name,
        expected_email,
        application.id,
        application.ecf_id,
        user.id,
        user.ecf_id,
        user.trn,
        user.trn_verified,
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
        expected_started,
        application.lead_provider_approval_status,
        application.training_status,
        application.headteacher_status,
        cohort.start_year,
      ]
    end

    let(:expected_name) { user.full_name }
    let(:expected_email) { user.email }
    let(:expected_started) { false }
    let(:expected_csv) { CSV.generate_lines([headers, expected_data]) }

    context "when there are no started declarations" do
      it "produces a CSV with Started Course: false" do
        subject.call
        file.rewind
        expect(file.read).to eq(expected_csv)
      end
    end

    context "when there is a started declaration" do
      let(:expected_started) { true }

      before do
        create(:declaration, :started, cohort: cohort, application: application)
      end

      it "produces a CSV with Started Course: true" do
        subject.call
        file.rewind
        expect(file.read).to eq(expected_csv)
      end
    end

    context "when the training status is nil" do
      let(:expected_name) { nil }
      let(:expected_email) { nil }

      before do
        application.update!(training_status: nil)
      end

      it "produces a CSV with no name or email" do
        subject.call
        file.rewind
        expect(file.read).to eq(expected_csv)
      end
    end
  end
end
