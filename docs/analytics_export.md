[< Back to Navigation](../README.md)

# DfE Analytics

## Summary

For the purpose of analytics, we send data to Google Cloud Platform (GCP) BigQuery, using the [DfE::Analytics](https://github.com/DFE-Digital/dfe-analytics) gem.


## Enabling analytics

Analytics is enabled via a feature flag in the admin console.


## Entity table checks

We have the `config.entity_table_checks_enabled` config option set to `true`, and the `CheckAnalyticsEntity` job ensures the latest version of an entity table in BigQuery is in sync with the database.


## Environment variables

The following environment variables are required:

* `BIGQUERY_DFE_ANALYTICS_API_JSON_KEY` contains the credentials JSON file


## Review apps

To test the analytics export on a review app, you can use the following steps:
1. Set the `BIGQUERY_DFE_ANALYTICS_API_JSON_KEY` environment variable, or set the credentials on the review app using `rails credentials:edit`
1. Enable the DfE Analytics feature flag in the admin console
1. DfE Analytics events should be viewable on the GCP BigQuery console, in the `npq_events_review` dataset


## Creating datasets and tables

There are datasets for each environment (i.e. `npq_events_production`, `npq_events_sandbox`, `npq_events_staging`, `npq_events_review`),
and an `events` table in each dataset.

If we need to create a new dataset for a new environment, the following process can be used:

1. In the GCP console, navigate to BigQuery, and create a new dataset with the following:
   - use London region (europe-west2)
   - for encryption use "Cloud KMS key" and use the "Enter key manually" to set the key to the same one used by other datasets
   - set the "Time Travel Window" to 7 days
1. Go to an existing `events` table, and on the schema tab, check the first checkbox to check all fields, then click on "Copy" and "Copy as JSON"
1. In the new dataset, create a new empty table called `events`, with the following:
   - for the schema, use the "Edit as text" option, and paste the JSON from the previous step
   - for partitioning settings, partition by field "occurred_at", with partitioning type "By day"
   - for clustering settings, cluster by field "event_type"
   - in Advanced options, set the encryption to "Cloud KMS key" and use the "Enter key manually" to set the key to the same one used by other tables


### Helper scripts

The [list_records.rb](analytics_export_scripts/list_records.rb) is an example script to list BigQuery records.
