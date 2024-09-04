require "rails_helper"

RSpec.describe Migration::Migrators::School do
  it_behaves_like "a migrator", :school, [] do
    def create_ecf_resource
      create(:ecf_migration_school, :with_applications)
    end

    def create_npq_resource(ecf_resource)
      create(:school, urn: ecf_resource.urn, name: ecf_resource.name.upcase)
    end

    def setup_failure_state
      # School in ECF with no match in NPQ reg.
      create(:ecf_migration_school, :with_applications)
    end

    describe "#call" do
      it "does not process schools that have no applications" do
        create(:ecf_migration_school)
        expect { instance.call }.to change { data_migration.reload.processed_count }.by(Migration::Ecf::School.count - 1)
      end

      it "records a failure when the school matches on URN but not name" do
        ecf_school = create(:ecf_migration_school, :with_applications)
        create(:school, urn: ecf_school.urn, name: "Different Name")
        instance.call
        expect(failure_manager).to have_received(:record_failure).with(ecf_school, /Couldn't find School/)
      end
    end
  end
end
