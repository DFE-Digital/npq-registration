# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "a migrator" do |model, dependencies|
  let(:worker) { 0 }
  let(:instance) { described_class.new(worker:) }
  let(:data_migration) { create(:data_migration, model:, worker: 0) }
  let(:failure_manager) { instance_double(Migration::FailureManager, record_failure: nil) }
  let(:ecf_resource1) { create_ecf_resource }
  let(:ecf_resource2) { create_ecf_resource }
  let(:ecf_class) { ecf_resource1.class }
  let(:records_per_worker) { 3 }
  let(:model_name) { model.to_s }

  before do
    create_npq_resource(ecf_resource1)
    create_npq_resource(ecf_resource2)

    allow(described_class).to receive(:records_per_worker).and_return(records_per_worker)
    allow(Migration::FailureManager).to receive(:new).with(data_migration:) { failure_manager }
  end

  describe ".prepare!" do
    subject(:prepare!) { described_class.prepare! }

    it "creates a pending data migrations" do
      expect { prepare! }.to change(Migration::DataMigration, :count).by(1)
      expect(Migration::DataMigration.all).to all(be_pending)
    end

    context "when there are enough models for two workers" do
      before { allow(described_class).to receive(:record_count).and_return(records_per_worker + 1) }

      it "creates two pending data migrations" do
        expect { prepare! }.to change(Migration::DataMigration, :count).by(2)
        expect(Migration::DataMigration.all).to all(be_pending)
      end
    end
  end

  describe ".record_count" do
    subject { described_class.record_count }

    it { is_expected.to eq(2) }
  end

  describe ".records_per_worker" do
    subject { described_class.records_per_worker }

    it { is_expected.to eq(records_per_worker) }
  end

  describe ".number_of_workers" do
    subject { described_class.number_of_workers }

    it { is_expected.to eq(1) }

    context "when there are enough models for two workers" do
      before { allow(described_class).to receive(:record_count).and_return(records_per_worker + 1) }

      it { is_expected.to eq(2) }
    end

    context "when there are no models" do
      before { allow(described_class).to receive(:record_count).and_return(0) }

      it { is_expected.to eq(1) }
    end
  end

  describe ".model" do
    subject { described_class.model }

    it { is_expected.to eq(model) }
  end

  describe ".runnable?" do
    subject { described_class }

    if dependencies.empty?
      it { is_expected.to be_runnable }

      context "when the model is already queued" do
        before { data_migration.update!(queued_at: Time.zone.now) }

        it { is_expected.not_to be_runnable }
      end
    else
      context "when the dependencies are not complete" do
        before { create(:data_migration, model: dependencies.sample) }

        it { is_expected.not_to be_runnable }
      end

      context "when the dependencies are all complete" do
        before { create(:data_migration, :completed, model: dependencies.sample) }

        it { is_expected.to be_runnable }

        context "when the model is already queued" do
          before { data_migration.update!(queued_at: Time.zone.now) }

          it { is_expected.not_to be_runnable }
        end
      end
    end
  end

  describe ".dependencies" do
    subject { described_class.dependencies }

    it { is_expected.to eq(dependencies) }
  end

  describe "#queue" do
    subject(:queue) { described_class.queue }

    it "marks the data migrations as queued" do
      expect { queue }.to change { data_migration.reload.queued_at }.from(nil).to(be_within(5.seconds).of(Time.zone.now))
    end

    it "queues a job for the migration" do
      expect { queue }.to have_enqueued_job(MigratorJob).with(migrator: described_class, worker: 0)
    end

    context "when there are models across multiple workers" do
      let(:records_per_worker) { 1 }

      before { create(:data_migration, model:, worker: 1) }

      it "queues a job for each worker" do
        expect { queue }.to have_enqueued_job(MigratorJob).with(migrator: described_class, worker: 0)
          .and(have_enqueued_job(MigratorJob).with(migrator: described_class, worker: 1))
      end
    end
  end

  describe "#call" do
    subject(:call) { instance.call }

    it "sets the started_at, total_count of the migration" do
      expect { call }.to change { data_migration.reload.started_at }.from(nil).to(be_within(5.seconds).of(Time.zone.now))
      .and(change(data_migration, :total_count).from(nil).to(2))
    end

    it "increments the processed count" do
      expect { call }.to change { data_migration.reload.processed_count }.by(2).and(not_change { data_migration.failure_count })
    end

    it "sets the completed_at" do
      expect { call }.to change { data_migration.reload.completed_at }.from(nil).to(be_within(5.seconds).of(Time.zone.now))
    end

    it "queues a follow up migration" do
      expect { call }.to have_enqueued_job(MigrationJob)
    end

    it "logs out as it runs" do
      allow(Rails.logger).to receive(:info)
      expect(Rails.logger).to receive(:info).with("Migration started", { model: model_name, worker: 0, total_count: 2, processed_count: 0 })
      expect(Rails.logger).to receive(:info).with("Migration completed", { model: model_name, worker: 0, total_count: 2, processed_count: 2 })
      call
    end

    context "when retrying a migration" do
      before do
        setup_failure_state
        instance.call
      end

      it "resets the processed/failure counts" do
        call
        data_migration.reload
        expect(data_migration.processed_count).to eq(3)
        expect(data_migration.failure_count).to eq(1)
      end
    end

    context "when there is a failure" do
      before { setup_failure_state }

      it "increments the failure/processed counts and logs the failure" do
        expect { call }.to change { data_migration.reload.failure_count }.by(1).and(change(data_migration, :processed_count).by(3))
        expect(failure_manager).to have_received(:record_failure).with(be_a(ecf_class), be_a(String))
      end
    end

    context "when there are models across multiple workers" do
      let(:records_per_worker) { 1 }

      before { create(:data_migration, model:, worker: 1) }

      it "only processes a portion of the models" do
        expect { call }.to change { data_migration.reload.processed_count }.by(1)
      end

      it "sets the total_count of the number of models this worker will process" do
        expect { call }.to change { data_migration.reload.total_count }.from(nil).to(1)
      end

      it "logs out as it runs" do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info).with("Migration started", { model: model_name, worker: 0, total_count: 1, processed_count: 0 })
        expect(Rails.logger).to receive(:info).with("Migration completed", { model: model_name, worker: 0, total_count: 1, processed_count: 1 })
        call
      end

      it "does not queue a follow up migration until all migrators have finished" do
        expect { call }.not_to(have_enqueued_job(MigrationJob))
        expect { described_class.new(worker: 1).call }.to(have_enqueued_job(MigrationJob))
      end
    end
  end
end
