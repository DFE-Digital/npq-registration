require "rails_helper"

RSpec.describe Migration::Migrators::Course do
  let(:instance) { described_class.new }

  subject { instance.call }

  describe "#call" do
    before do
      create(:ecf_migration_npq_course)
      create(:ecf_migration_npq_course)

      create(:data_migration, model: :course)
    end

    it "migrates the courses" do
      subject

      expect(Migration::DataMigration.find_by(model: :course).processed_count).to eq(2)
    end

    context "when a courses is not correctly created" do
      let!(:ecf_migration_npq_course) { create(:ecf_migration_npq_course) }
      let(:course) { create(:course) }

      before do
        course.update!(ecf_id: ecf_migration_npq_course.id)

        allow(Course).to receive(:find_or_initialize_by).and_call_original
        allow(Course).to receive(:find_or_initialize_by).with(ecf_id: ecf_migration_npq_course.id).and_return(course)
        allow(course).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "increments the failure count" do
        subject

        expect(Migration::DataMigration.find_by(model: :course).processed_count).to eq(3)
        expect(Migration::DataMigration.find_by(model: :course).failure_count).to eq(1)
      end

      it "calls FailureManager with correct params" do
        expect_any_instance_of(Migration::FailureManager).to receive(:record_failure).with(ecf_migration_npq_course, "Record invalid").and_call_original

        subject
      end
    end
  end
end
