require "google/cloud/bigquery"

class Exporters::AnalyticsReport
  PROJECT = "ecf-bq".freeze
  DATASET = "npq_registration".freeze
  TABLE = ENV.fetch("BIGQUERY_APPLICATION_TABLE", "cron_test_applications")

  def call
    save_temp_file
    upload_file_to_bigquery
  ensure
    @tmp.unlink
  end

private

  def save_temp_file
    @tmp = Tempfile.new("analytics_report")
    report = Report.last
    @tmp.write(report.data)
    @tmp.close
  end

  def upload_file_to_bigquery
    bigquery = Google::Cloud::Bigquery.new(project: PROJECT)
    dataset = bigquery.dataset(DATASET)
    table = dataset.table(TABLE)

    load_job = table.load_job @tmp.path, autodetect: true, write: "WRITE_TRUNCATE"

    Rails.logger.info "[AnalyticsReport] Data loading"

    load_job.wait_until_done!

    if load_job.failed?
      Rails.logger.info "[AnalyticsReport] Job failed with errors:"
      load_job.errors.each do |error|
        puts "[AnalyticsReport] error: #{error}"
      end
    else
      Rails.logger.info "[AnalyticsReport] Data loaded successfully"
    end
  end
end
