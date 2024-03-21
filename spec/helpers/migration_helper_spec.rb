require "rails_helper"

RSpec.describe MigrationHelper, type: :helper do
  around do |example|
    freeze_time { example.run }
  end

  describe ".migration_started_at" do
    subject { helper.migration_started_at(data_migrations) }

    let(:data_migrations) { [] }

    it { is_expected.to eq(Time.zone.now) }

    context "when there are data migrations with started_at dates" do
      let(:data_migrations) do
        [
          Migration::DataMigration.new(model: "model1", started_at: 2.days.ago),
          Migration::DataMigration.new(model: "model2", started_at: 3.days.ago),
          Migration::DataMigration.new(model: "model3", started_at: 1.day.ago),
        ]
      end

      it { is_expected.to eq(3.days.ago) }
    end
  end

  describe ".migration_completed_at" do
    subject { helper.migration_completed_at(data_migrations) }

    let(:data_migrations) do
      [
        Migration::DataMigration.new(model: "model1", completed_at: 2.days.ago),
        Migration::DataMigration.new(model: "model2", completed_at: 1.day.ago),
        Migration::DataMigration.new(model: "model3", completed_at: 3.days.ago),
      ]
    end

    it { is_expected.to eq(1.day.ago) }
  end

  describe ".migration_duration_in_words" do
    subject { helper.migration_duration_in_words(data_migrations) }

    let(:data_migrations) do
      [
        Migration::DataMigration.new(model: "model1", started_at: 3.days.ago, completed_at: 1.day.ago),
        Migration::DataMigration.new(model: "model1", started_at: 5.days.ago, completed_at: 2.days.ago),
      ]
    end

    it { is_expected.to eq("4 days") }
  end

  describe ".data_migration_status_tag" do
    subject { helper.data_migration_status_tag(data_migration) }

    context "when the data migration is pending" do
      let(:data_migration) { Migration::DataMigration.new(model: "model") }

      it { is_expected.to have_css("strong.govuk-tag.govuk-tag--grey", text: "Pending") }
    end

    context "when the data migration is in progress" do
      let(:data_migration) { Migration::DataMigration.new(model: "model", started_at: 10.minutes.ago, total_count: 100, processed_count: 50) }

      it { is_expected.to have_css("strong.govuk-tag.govuk-tag--blue", text: "In progress - 50%") }
    end

    context "when the data migration is complete" do
      let(:data_migration) { Migration::DataMigration.new(model: "model", started_at: 5.minutes.ago, completed_at: 1.minute.ago) }

      it { is_expected.to have_css("strong.govuk-tag.govuk-tag--green", text: "Completed") }
    end
  end

  describe ".data_migration_failure_count_tag" do
    subject { helper.data_migration_failure_count_tag(data_migration) }

    context "when the data migration has no failures" do
      let(:data_migration) { Migration::DataMigration.new(failure_count: 0) }

      it { is_expected.to be_nil }
    end

    context "when the data migration has failures" do
      let(:data_migration) { Migration::DataMigration.new(failure_count: 1_234) }

      it { is_expected.to have_css("strong.govuk-tag.govuk-tag--red", text: "1,234") }
    end
  end

  describe ".data_migration_total_count_tag" do
    subject { helper.data_migration_total_count_tag(data_migration) }

    context "when the data migration has no total_count" do
      let(:data_migration) { Migration::DataMigration.new(total_count: nil) }

      it { is_expected.to be_nil }
    end

    context "when the data migration has a total_count" do
      let(:data_migration) { Migration::DataMigration.new(total_count: 5_000) }

      it { is_expected.to have_css("strong.govuk-tag.govuk-tag--blue", text: "5,000") }
    end
  end

  describe ".data_migration_percentage_migrated_successfully_tag" do
    subject(:tag) { Nokogiri.parse(helper.data_migration_percentage_migrated_successfully_tag(data_migration)) }

    context "when the percentage is 100" do
      let(:data_migration) { Migration::DataMigration.new(processed_count: 100, failure_count: 0) }

      it { is_expected.to have_css("strong.govuk-tag.govuk-tag--green", text: "100%") }
    end

    context "when the percentage is between 80 and 100" do
      let(:data_migration) { Migration::DataMigration.new(processed_count: 100, failure_count: 15) }

      it { is_expected.to have_css("strong.govuk-tag.govuk-tag--yellow", text: "85%") }
    end

    context "when the percentage is less than 80" do
      let(:data_migration) { Migration::DataMigration.new(processed_count: 100, failure_count: 25) }

      it { is_expected.to have_css("strong.govuk-tag.govuk-tag--red", text: "75%") }
    end
  end

  describe "#data_migration_download_failures_report_link" do
    subject { helper.data_migration_download_failures_report_link(data_migration) }

    context "when data migration failures count is positive" do
      let(:data_migration) { create(:data_migration, :with_failures)  }

      it { is_expected.to include("/npq-separation/migration/migrations/download_report/#{data_migration.id}") }
    end

    context "when data migration failures count is not positive" do
      let(:data_migration) { create(:data_migration) }

      it { is_expected.to be_nil }
    end
  end
end
