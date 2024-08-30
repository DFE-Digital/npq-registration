require "rails_helper"

RSpec.describe Migration::Migrators::Application do
  it_behaves_like "a migrator", :application, [] do
    def create_ecf_resource
      create(:ecf_migration_npq_application)
    end

    def create_npq_resource(ecf_resource)
      create(:application, ecf_id: ecf_resource.id, **ecf_resource.slice(described_class::ATTRIBUTES_TO_COMPARE))
    end

    def setup_failure_state
      # NPQApplication in ECF with no match in NPQ reg.
      create(:ecf_migration_npq_application)
    end

    describe "#call" do
      it "records a failure when the attribute values do not match" do
        ecf_resource1.update!(teacher_catchment: "any")
        instance.call
        expect(failure_manager).to have_received(:record_failure).with(ecf_resource1, /Validation failed/)
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
