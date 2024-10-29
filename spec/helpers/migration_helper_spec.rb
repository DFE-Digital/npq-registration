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
          create(:data_migration, :in_progress, started_at: 2.days.ago),
          create(:data_migration, :in_progress, started_at: 3.days.ago),
          create(:data_migration, :in_progress, started_at: 1.day.ago),
        ]
      end

      it { is_expected.to eq(3.days.ago) }
    end
  end

  describe ".migration_completed_at" do
    subject { helper.migration_completed_at(data_migrations) }

    let(:data_migrations) do
      [
        create(:data_migration, :completed, completed_at: 2.days.ago),
        create(:data_migration, :completed, completed_at: 1.day.ago),
        create(:data_migration, :completed, completed_at: 3.days.ago),
      ]
    end

    it { is_expected.to eq(1.day.ago) }
  end

  describe ".migration_duration_in_words" do
    subject { helper.migration_duration_in_words(data_migrations) }

    let(:data_migrations) do
      [
        create(:data_migration, :completed, started_at: 2.days.ago, completed_at: 1.day.ago),
        create(:data_migration, :completed, started_at: 5.days.ago, completed_at: 2.days.ago),
      ]
    end

    it { is_expected.to eq("4 days") }
  end

  describe ".data_migration_status_tag" do
    subject { helper.data_migration_status_tag(data_migration) }

    context "when the data migration is queued" do
      let(:data_migration) { create(:data_migration, :queued) }

      it { is_expected.to have_css("strong.govuk-tag.govuk-tag--blue", text: "Queued") }
    end

    context "when the data migration is pending" do
      let(:data_migration) { create(:data_migration) }

      it { is_expected.to have_css("strong.govuk-tag.govuk-tag--grey", text: "Pending") }
    end

    context "when the data migration is in progress" do
      let(:data_migration) { create(:data_migration, :in_progress, total_count: 2, processed_count: 1) }

      it { is_expected.to have_css("strong.govuk-tag.govuk-tag--yellow", text: "In progress - 50%") }
    end

    context "when the data migration is complete" do
      let(:data_migration) { create(:data_migration, :completed) }

      it { is_expected.to have_css("strong.govuk-tag.govuk-tag--green", text: "Completed") }
    end
  end

  describe "aggregate data migration helpers" do
    describe ".data_migration_failure_count_tag" do
      subject { helper.data_migration_failure_count_tag(data_migrations) }

      context "when the data migrations have no failures" do
        let(:data_migrations) do
          [
            create(:data_migration, :completed, failure_count: 0),
            create(:data_migration, :completed, failure_count: 0),
          ]
        end

        it { is_expected.to be_nil }
      end

      context "when the data migrations have failures" do
        let(:data_migrations) do
          [
            create(:data_migration, :with_failures, failure_count: 100),
            create(:data_migration, :with_failures, failure_count: 999),
          ]
        end

        it { is_expected.to have_css("strong.govuk-tag.govuk-tag--red", text: "1,099") }
      end
    end

    describe ".data_migration_total_count_tag" do
      subject { helper.data_migration_total_count_tag(data_migrations) }

      context "when the data migrations have no total_count" do
        let(:data_migrations) do
          [
            create(:data_migration, :with_failures, total_count: 0),
            create(:data_migration, :with_failures, total_count: 0),
          ]
        end

        it { is_expected.to be_nil }
      end

      context "when the data migrations have a total_count" do
        let(:data_migrations) do
          [
            create(:data_migration, :with_failures, total_count: 2_500),
            create(:data_migration, :with_failures, total_count: 2_500),
          ]
        end

        it { is_expected.to have_css("strong.govuk-tag.govuk-tag--blue", text: "5,000") }
      end
    end

    describe ".data_migration_percentage_migrated_successfully_tag" do
      subject(:tag) { Nokogiri.parse(helper.data_migration_percentage_migrated_successfully_tag(data_migrations)) }

      context "when the percentage is 100" do
        let(:data_migration) { create(:data_migration, :in_progress, processed_count: 100, failure_count: 0) }
        let(:data_migrations) do
          [
            create(:data_migration, :in_progress, processed_count: 100, failure_count: 0),
            create(:data_migration, :in_progress, processed_count: 100, failure_count: 0),
          ]
        end

        it { is_expected.to have_css("strong.govuk-tag.govuk-tag--green", text: "100%") }
      end

      context "when the percentage is between 80 and 100" do
        let(:data_migrations) do
          [
            create(:data_migration, :in_progress, processed_count: 100, failure_count: 15),
            create(:data_migration, :in_progress, processed_count: 100, failure_count: 15),
          ]
        end

        it { is_expected.to have_css("strong.govuk-tag.govuk-tag--yellow", text: "85%") }
      end

      context "when the percentage is less than 80" do
        let(:data_migrations) do
          [
            create(:data_migration, :in_progress, processed_count: 100, failure_count: 25),
            create(:data_migration, :in_progress, processed_count: 100, failure_count: 25),
          ]
        end

        it { is_expected.to have_css("strong.govuk-tag.govuk-tag--red", text: "75%") }
      end

      context "when the percentage would round up to 100" do
        let(:data_migrations) do
          [
            create(:data_migration, :in_progress, processed_count: 100_000, failure_count: 1),
          ]
        end

        it { is_expected.to have_css("strong.govuk-tag.govuk-tag--yellow", text: "99%") }
      end
    end

    describe "#data_migration_download_failures_report_link" do
      subject { helper.data_migration_download_failures_report_link(data_migrations) }

      context "when data migration failures count is positive" do
        let(:data_migrations) do
          [
            create(:data_migration, :with_failures),
            create(:data_migration, :with_failures),
          ]
        end

        it { is_expected.to include("/npq-separation/migration/migrations/download_report/#{data_migrations.sample.model}") }
      end

      context "when data migration failures count is not positive" do
        let(:data_migrations) do
          [
            create(:data_migration),
            create(:data_migration),
          ]
        end

        it { is_expected.to be_nil }
      end
    end
  end

  describe ".response_comparison_status_tag" do
    subject { helper.response_comparison_status_tag(different) }

    context "when not different" do
      let(:different) { false }

      it { is_expected.to have_css("strong.govuk-tag.govuk-tag--green", text: "EQUAL") }

      context "when equal_text is specified" do
        subject { helper.response_comparison_status_tag(different, equal_text: "yes") }

        it { is_expected.to have_css("strong.govuk-tag.govuk-tag--green", text: "YES") }
      end
    end

    context "when different" do
      let(:different) { true }

      it { is_expected.to have_css("strong.govuk-tag.govuk-tag--red", text: "DIFFERENT") }

      context "when different_text is specified" do
        subject { helper.response_comparison_status_tag(different, different_text: "no") }

        it { is_expected.to have_css("strong.govuk-tag.govuk-tag--red", text: "NO") }
      end
    end
  end

  describe ".response_comparison_performance" do
    let(:comparisons) { [response_comparison1, response_comparison2] }

    subject { helper.response_comparison_performance(comparisons) }

    context "when NPQ is slower" do
      let(:response_comparison1) { build(:response_comparison, npq_response_time_ms: 2, ecf_response_time_ms: 1) }
      let(:response_comparison2) { build(:response_comparison, npq_response_time_ms: 2, ecf_response_time_ms: 1) }

      it { is_expected.to have_css("strong", text: "🐌 0.5x as fast") }
    end

    context "when NPQ is faster" do
      let(:response_comparison1) { build(:response_comparison, npq_response_time_ms: 1, ecf_response_time_ms: 2) }
      let(:response_comparison2) { build(:response_comparison, npq_response_time_ms: 1, ecf_response_time_ms: 2) }

      it { is_expected.to have_css("i", text: "🚀 2x faster") }
    end

    context "when passed a single comparison" do
      let(:comparisons) { create(:response_comparison, npq_response_time_ms: 1, ecf_response_time_ms: 3) }

      it { is_expected.to have_css("i", text: "🚀 3x faster") }
    end
  end

  describe ".response_comparison_detail_path" do
    subject { helper.response_comparison_detail_path([response_comparison1, response_comparison2]) }

    context "when at least one is different" do
      let(:response_comparison1) { create(:response_comparison, :different) }
      let(:response_comparison2) { create(:response_comparison, :equal) }

      it { is_expected.to include(%r{/npq-separation/migration/parity_checks/response_comparisons/(#{response_comparison1.id}|#{response_comparison2.id})}) }
    end

    context "when all are equal" do
      let(:response_comparison1) { build(:response_comparison, :equal) }
      let(:response_comparison2) { build(:response_comparison, :equal) }

      it { is_expected.to be_nil }
    end
  end

  describe ".response_comparison_response_duration_human_readable" do
    subject { helper.response_comparison_response_duration_human_readable(comparisons, :ecf_response_time_ms) }

    context "when the average duration is less than 1 second" do
      let(:comparisons) do
        [
          create(:response_comparison, ecf_response_time_ms: 600),
          create(:response_comparison, ecf_response_time_ms: 400),
        ]
      end

      it { is_expected.to eq("500ms") }
    end

    context "when the duration is 1 second" do
      let(:comparisons) do
        [
          create(:response_comparison, ecf_response_time_ms: 1_000),
          create(:response_comparison, ecf_response_time_ms: 1_000),
        ]
      end

      it { is_expected.to eq("1 second") }
    end

    context "when the duration is more than 1 second" do
      let(:comparisons) do
        [
          create(:response_comparison, ecf_response_time_ms: 2_000),
          create(:response_comparison, ecf_response_time_ms: 2_200),
        ]
      end

      it { is_expected.to eq("2 seconds") }
    end

    context "when passed a single comparison" do
      let(:comparisons) { create(:response_comparison, ecf_response_time_ms: 1_000) }

      it { is_expected.to eq("1 second") }
    end
  end

  describe ".response_comparison_status_code_tag" do
    subject { helper.response_comparison_status_code_tag(status_code) }

    context "when the status code is less than or equal to 299" do
      let(:status_code) { 200 }

      it { is_expected.to have_css("strong.govuk-tag.govuk-tag--green", text: "200") }
    end

    context "when the status code is less than or equal to 399" do
      let(:status_code) { 302 }

      it { is_expected.to have_css("strong.govuk-tag.govuk-tag--yellow", text: "302") }
    end

    context "when the status code is greater than 399" do
      let(:status_code) { 500 }

      it { is_expected.to have_css("strong.govuk-tag.govuk-tag--red", text: "500") }
    end
  end

  describe ".response_comparison_page_summary" do
    let(:comparison) { create(:response_comparison, :different, page: 1) }

    subject { helper.response_comparison_page_summary(comparison) }

    it { is_expected.to have_css(".govuk-grid-row .govuk-grid-column-two-thirds", text: "Page 1") }
    it { is_expected.to have_css(".govuk-grid-row .govuk-grid-column-one-third", text: "ECF: 200 NPQ: 201") }
  end

  describe ".contains_duplicate_ids?" do
    subject { helper.contains_duplicate_ids?(comparisons, :npq_response_body_ids) }

    context "when the comparisons contain duplicates across all comparisons" do
      let(:comparisons) do
        [
          create(:response_comparison, :different, npq_response_body: %({ "data": [{ "id": "1" }, { "id": "2" }, { "id": "3" }] })),
          create(:response_comparison, :different, npq_response_body: %({ "data": [{ "id": "1" }, { "id": "4" }, { "id": "5" }] })),
        ]
      end

      it { is_expected.to be(true) }
    end

    context "when the comparisons contain duplicates in individual comparisons" do
      let(:comparisons) do
        [
          create(:response_comparison, :different, npq_response_body: %({ "data": [{ "id": "1" }, { "id": "1" }, { "id": "3" }] })),
          create(:response_comparison, :different, npq_response_body: %({ "data": [{ "id": "4" }, { "id": "5" }, { "id": "6" }] })),
        ]
      end

      it { is_expected.to be(true) }
    end

    context "when the comparisons do not contain duplicates" do
      let(:comparisons) do
        [
          create(:response_comparison, :different, npq_response_body: %({ "data": [{ "id": "1" }, { "id": "2" }, { "id": "3" }] })),
          create(:response_comparison, :different, npq_response_body: %({ "data": [{ "id": "4" }, { "id": "5" }, { "id": "6" }] })),
        ]
      end

      it { is_expected.to be(false) }
    end
  end
end
