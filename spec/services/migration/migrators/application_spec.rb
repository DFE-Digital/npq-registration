require "rails_helper"

RSpec.describe Migration::Migrators::Application do
  it_behaves_like "a migrator", :application, %i[private_childcare_provider itt_provider cohort lead_provider schedule course user school] do
    let(:records_per_worker_divider) { 2 }

    def create_ecf_resource
      create(:ecf_migration_npq_application, :accepted)
    end

    def create_npq_resource(ecf_resource)
      cohort = create(:cohort, ecf_id: ecf_resource.cohort_id, start_year: ecf_resource.cohort.start_year)
      ecf_schedule = ecf_resource.profile.schedule
      create(:schedule, :npq_aso_december, ecf_id: ecf_schedule.id, cohort:, identifier: ecf_schedule.schedule_identifier)
      create(:private_childcare_provider, provider_urn: ecf_resource.private_childcare_provider_urn)

      school = create(:school, urn: ecf_resource.school_urn, ukprn: ecf_resource.school_ukprn)
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
        application = Application.find_by!(ecf_id: ecf_resource1.id)
        expect(application.attributes).to include(ecf_resource1.attributes.slice(*described_class::ATTRIBUTES))
        expect(application.training_status).to eq(ecf_resource1.profile.training_status)
        expect(application.ukprn).to eq(ecf_resource1.school_ukprn)
        expect(application.user.ecf_id).to eq(ecf_resource1.user.id)
        expect(application.accepted_at).to eq(ecf_resource1.profile.created_at)
      end

      it "sets the schedule from the ECF NPQApplication on the NPQ application" do
        instance.call

        application = Application.find_by!(ecf_id: ecf_resource1.id)
        ecf_schedule = ecf_resource1.profile.schedule
        expect(application.schedule.ecf_id).to eq(ecf_schedule.id)
      end

      it "sets the cohort from the ECF NPQApplication on the NPQ application" do
        instance.call

        application = Application.find_by!(ecf_id: ecf_resource1.id)
        expect(application.cohort.start_year).to eq(ecf_resource1.cohort.start_year)
      end

      it "sets the ITT provider from the ECF NPQApplication on the NPQ application" do
        instance.call

        application = Application.find_by!(ecf_id: ecf_resource1.id)
        expect(application.itt_provider.legal_name).to eq(ecf_resource1.itt_provider)
      end

      it "sets the private childcare provider from the ECF NPQApplication on the NPQ application" do
        instance.call

        application = Application.find_by!(ecf_id: ecf_resource1.id)
        expect(application.private_childcare_provider.provider_urn).to eq(ecf_resource1.private_childcare_provider_urn)
      end

      it "overrides school from ECF NPQApplication on the NPQ application" do
        application = Application.find_by!(ecf_id: ecf_resource1.id)
        application.update!(school: create(:school, urn: "111333"))
        instance.call

        expect(application.reload.school.urn).to eq(ecf_resource1.school_urn)
      end

      it "overrides lead_provider from ECF NPQApplication on the NPQ application" do
        application = Application.find_by!(ecf_id: ecf_resource1.id)
        application.update!(lead_provider: create(:lead_provider, name: "Test Provider"))
        instance.call

        expect(application.reload.lead_provider.ecf_id).to eq(ecf_resource1.npq_lead_provider.id)
      end

      it "overrides course from ECF NPQApplication on the NPQ application" do
        application = Application.find_by!(ecf_id: ecf_resource1.id)
        application.update!(course: create(:course, name: "Test Course"))

        instance.call

        expect(application.reload.course.ecf_id).to eq(ecf_resource1.npq_course.id)
      end

      it "records a failure when the schedule cannot be found" do
        Schedule.find_by!(ecf_id: ecf_resource1.profile.schedule_id).destroy!
        instance.call
        expect(failure_manager).to have_received(:record_failure).with(ecf_resource1, /Couldn't find Schedule/)
      end

      it "records a failure when the cohort cannot be found" do
        Cohort.find_by!(ecf_id: ecf_resource1.cohort_id).update!(ecf_id: SecureRandom.uuid)
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

      it "treats the schedule, training_status and accepted_at as optional (as profile can be nil)" do
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

      context "when application does not exist on NPQ" do
        it "creates application" do
          created_at = 10.days.ago
          updated_at = 3.days.ago

          ::Application.find_by!(ecf_id: ecf_resource1.id).destroy!
          expect(::Application.find_by_ecf_id(ecf_resource1.id)).to be_nil

          ecf_resource1.update!(created_at:, updated_at:)

          instance.call

          application = ::Application.find_by_ecf_id!(ecf_resource1.id)
          expect(application.created_at.to_s).to eq(created_at.to_s)
          expect(application.updated_at.to_s).to eq(updated_at.to_s)
        end
      end

      context "when the school ukprn does not match with the one pulled in from ECF" do
        before { ecf_resource1.update!(school_ukprn: rand(10_000_000..99_999_999).to_s) }

        it "records a failure" do
          instance.call

          expect(failure_manager).to have_received(:record_failure).once.with(ecf_resource1, /Validation failed: School UKPRN does not match/)
        end
      end

      context "when the school ukprn pulled in from ECF is nil" do
        before { ecf_resource1.update!(school_ukprn: nil) }

        it "overrides ukprn from Schools table on the NPQ application" do
          application = Application.find_by!(ecf_id: ecf_resource1.id)
          expect(application.ukprn).to be_nil

          instance.call

          expect(application.reload.ukprn).to eq(application.school.ukprn)
        end
      end

      context "when setting timestamps from ECF" do
        let(:created_at) { 10.days.ago }
        let(:updated_at) { 3.days.ago }

        it "sets the timestamps from ECF when ukprn does not change" do
          ecf_resource1.update!(created_at:, updated_at:)

          with_versioning do
            expect(PaperTrail).to be_enabled

            instance.call

            application = ::Application.find_by_ecf_id!(ecf_resource1.id)
            expect(application.created_at.to_s).to eq(created_at.to_s)
            expect(application.updated_at.to_s).to eq(updated_at.to_s)

            version = application.versions.last
            expect(version.note).to eq("Changes migrated from ECF to NPQ")
            expect(version.object_changes["created_at"].last).to eq(created_at.iso8601(3))
            expect(version.object_changes["updated_at"].last).to eq(updated_at.iso8601(3))
          end
        end

        it "sets updated_at to now when ukprn is nil" do
          ecf_resource1.update!(created_at:, updated_at:, school_ukprn: nil)

          freeze_time do
            with_versioning do
              expect(PaperTrail).to be_enabled

              instance.call

              application = ::Application.find_by_ecf_id!(ecf_resource1.id)
              expect(application.created_at.to_s).to eq(created_at.to_s)
              expect(application.updated_at.to_s).to eq(Time.zone.now.to_s)

              version = application.versions.last
              expect(version.note).to eq("Changes migrated from ECF to NPQ")
              expect(version.object_changes["created_at"].last).to eq(created_at.iso8601(3))
              expect(version.object_changes["updated_at"].last).to eq(Time.zone.now.iso8601(3))
            end
          end
        end
      end
    end
  end
end
