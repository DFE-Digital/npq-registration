require "google/cloud/bigquery"
def list_records(project_id, dataset_id, table_id)
  bigquery = Google::Cloud::Bigquery.new(project: project_id, credentials: JSON.parse(DfE::Analytics.config.bigquery_api_json_key))
  bigquery.dataset(dataset_id)

  query = "SELECT * FROM `#{dataset_id}.#{table_id}` LIMIT 10"
  rows = bigquery.query(query)

  rows.each do |row|
    puts row
  end
end
list_records "ecf-bq", "npq_events_review", "events"
