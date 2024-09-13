require "rails_helper"

RSpec.describe Migration::Migrators::Application do
  it_behaves_like "a migrator", :application, %i[cohort lead_provider schedule course user school] do
    def create_ecf_resource
      create(:ecf_migration_npq_application, :accepted)
    end

    def create_npq_resource(ecf_resource)
      cohort = create(:cohort, start_year: ecf_resource.cohort.start_year)
      ecf_schedule = ecf_resource.profile.schedule
      create(:schedule, :npq_aso_december, cohort:, identifier: ecf_schedule.schedule_identifier)
      create(:private_childcare_provider, provider_urn: ecf_resource.private_childcare_provider_urn)

      school = create(:school, urn: ecf_resource.school_urn)
      course = create(:course, identifier: ecf_resource.npq_course.identifier, ecf_id: ecf_resource.npq_course_id)
      lead_provider = create(:lead_provider, ecf_id: ecf_resource.npq_lead_provider_id)
      user = create(:user, ecf_id: ecf_resource.user.id)
      create(:application, ecf_id: ecf_resource.id, school:, course:, lead_provider:, user:)
    end

    def setup_failure_state
      # NPQApplication in ECF with no match in NPQ reg.
      create(:ecf_migration_npq_application)
    end

    describe "#call" do
      it "sets the attributes from the ECF NPQApplication on the NPQ application" do
        instance.call
        application = Application.find_by(ecf_id: ecf_resource1.id)
        expect(application.attributes).to include(ecf_resource1.attributes.slice(*described_class::ATTRIBUTES))
        expect(application.training_status).to eq(ecf_resource1.profile.training_status)
        expect(application.ukprn).to eq(ecf_resource1.school_ukprn)
      end

      it "sets the schedule from the ECF NPQApplication on the NPQ application" do
        instance.call

        application = Application.find_by(ecf_id: ecf_resource1.id)
        ecf_schedule = ecf_resource1.profile.schedule
        expect(application.schedule.identifier).to eq(ecf_schedule.schedule_identifier)
        expect(application.schedule.cohort.start_year).to eq(ecf_schedule.cohort.start_year)
        expect(application.schedule.course_group.name).to eq("support")
      end

      it "sets the cohort from the ECF NPQApplication on the NPQ application" do
        instance.call

        application = Application.find_by(ecf_id: ecf_resource1.id)
        expect(application.cohort.start_year).to eq(ecf_resource1.cohort.start_year)
      end

      it "sets the ITT provider from the ECF NPQApplication on the NPQ application" do
        instance.call

        application = Application.find_by(ecf_id: ecf_resource1.id)
        expect(application.itt_provider.legal_name).to eq(ecf_resource1.itt_provider)
      end

      it "sets the private childcare provider from the ECF NPQApplication on the NPQ application" do
        instance.call

        application = Application.find_by(ecf_id: ecf_resource1.id)
        expect(application.private_childcare_provider.provider_urn).to eq(ecf_resource1.private_childcare_provider_urn)
      end

      it "records a failure when the school in NPQ reg does not match the school in ECF" do
        Application.first.update!(school: create(:school, urn: "111333"))
        instance.call
        expect(failure_manager).to have_received(:record_failure).with(ecf_resource1, /School in ECF is different/)
      end

      it "records a failure when the school exists on the application in NPQ reg but not ECF" do
        ecf_resource1.update!(school_urn: nil)
        instance.call
        expect(failure_manager).to have_received(:record_failure).with(ecf_resource1, /School in ECF is different/)
      end

      it "does not record a failure when the school is nil for both ECF and NPQ reg" do
        ecf_resource1.update!(school_urn: nil)
        Application.find_by(ecf_id: ecf_resource1.id).update!(school: nil)
        instance.call
        expect(failure_manager).not_to have_received(:record_failure)
      end

      it "records a failure when the user in NPQ reg does not match the user in ECF" do
        Application.first.update!(user: create(:user))
        instance.call
        expect(failure_manager).to have_received(:record_failure).with(ecf_resource1, /User in ECF is different/)
      end

      it "records a failure when the course in NPQ reg does not match the course in ECF" do
        Application.first.update!(course: create(:course))
        instance.call
        expect(failure_manager).to have_received(:record_failure).with(ecf_resource1, /Course in ECF is different/)
      end

      it "records a failure when the lead provider in NPQ reg does not match the lead provider in ECF" do
        Application.first.update!(lead_provider: create(:lead_provider))
        instance.call
        expect(failure_manager).to have_received(:record_failure).with(ecf_resource1, /LeadProvider in ECF is different/)
      end

      it "records a failure when the schedule cannot be found" do
        ecf_resource1.profile.schedule.update!(schedule_identifier: "other-schedule")
        instance.call
        expect(failure_manager).to have_received(:record_failure).with(ecf_resource1, /Couldn't find Schedule/)
      end

      it "records a failure when the cohort cannot be found" do
        ecf_resource1.cohort.update!(start_year: "1999")
        instance.call
        expect(failure_manager).to have_received(:record_failure).with(ecf_resource1, /Couldn't find Cohort/)
      end

      it "records a failure when the ITT provider cannot be found" do
        ecf_resource1.update!(itt_provider: "other-provider")
        instance.call
        expect(failure_manager).to have_received(:record_failure).with(ecf_resource1, /Couldn't find IttProvider/)
      end

      it "records a failure when the private childcare provider cannot be found" do
        ecf_resource1.update!(private_childcare_provider_urn: "999999")
        instance.call
        expect(failure_manager).to have_received(:record_failure).with(ecf_resource1, /Couldn't find PrivateChildcareProvider/)
      end

      it "treats the schedule and training_status as optional (as profile can be nil)" do
        ecf_resource1.profile.destroy!
        instance.call
        expect(failure_manager).not_to have_received(:record_failure)
      end

      it "records a failure if applications exist in NPQ reg but not in ECF, but only on the first run" do
        orphan_application1 = create(:application)
        orphan_application2 = create(:application)

        described_class.new(worker: 0).call

        create(:data_migration, model: :application, worker: 1)
        described_class.new(worker: 1).call

        expect(failure_manager).to have_received(:record_failure).once.with(orphan_application1, /NPQApplication not found in ECF/)
        expect(failure_manager).to have_received(:record_failure).once.with(orphan_application2, /NPQApplication not found in ECF/)
      end
    end
  end
end
