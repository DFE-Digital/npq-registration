require "rails_helper"

RSpec.describe Migration::Migrators::School do
  let(:instance) { described_class.new }
  let(:find_data_migration) { Migration::DataMigration.find_by(model: :school) }

  subject(:migrate) { instance.call }

  describe "#call" do
    let(:failure_manager) { instance_double(Migration::FailureManager, record_failure: nil) }

    before do
      allow(Migration::FailureManager).to receive(:new) { failure_manager }

      described_class.prepare!
    end

    it "migrates schools that have applications" do
      ecf_school_1 = create(:ecf_migration_school, :with_applications)
      create(:school, urn: ecf_school_1.urn, name: ecf_school_1.name)

      ecf_school_2 = create(:ecf_migration_school, :with_applications)
      create(:school, urn: ecf_school_2.urn, name: ecf_school_2.name)

      migrate

      expect(find_data_migration.reload).to have_attributes(processed_count: 2, failure_count: 0)
    end

    it "does not migrate schools that do not have applications" do
      create(:ecf_migration_school)

      migrate

      expect(find_data_migration.reload).to have_attributes(processed_count: 0)
    end

    it "records a failure when a matching school cannot be found" do
      ecf_school = create(:ecf_migration_school, :with_applications)

      migrate

      expect(find_data_migration.reload).to have_attributes(processed_count: 1, failure_count: 1)

      expect(failure_manager).to have_received(:record_failure).with(
        ecf_school,
        "Couldn't find School with [WHERE \"schools\".\"urn\" = $1 AND \"schools\".\"name\" = $2]",
      )
    end

    it "records a failure when the school matches on URN but not name" do
      ecf_school = create(:ecf_migration_school, :with_applications)
      create(:school, urn: ecf_school.urn, name: "Different Name")

      migrate

      expect(find_data_migration.reload).to have_attributes(processed_count: 1, failure_count: 1)

      expect(failure_manager).to have_received(:record_failure).with(
        ecf_school,
        "Couldn't find School with [WHERE \"schools\".\"urn\" = $1 AND \"schools\".\"name\" = $2]",
      )
    end
  end
end
