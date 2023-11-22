[< Back to Navigation](../README.md)

# Big Query Upload

## Summary

For the purpuse of analytics team, we send data to their database.


## Data exporting

To see how data is being exported, see 2 files:

[GenerateDashoboardReportJob](../app/jobs/crons/generate_dashboard_report_job.rb)
[ScheduleUploadAnalyticsReportJob](../app/jobs/crons/schedule_upload_analytics_report_job.rb)

By following a code in above files, all parts can be easily understood.

## Devops

The environments are already set up, but in case of migration:

* env variable `GOOGLE_APPLICATION_CREDENTIALS` pointing to credentials json file should be created on the environments
* for production, env variable `BIGQUERY_APPLICATION_TABLE` should be set to `applications`
 
## Testing

To test upload:
1. Generate report
2. Run upload script on test database
3. Verify correct records in database

### Helper scripts

In case when testing table does not exists, one can be created with:

```shell
bq mk --table --description "test table" npq_registration.cron_test_applications applications.json
```
The table schema file is [here](analytics_export_scripts/applications.json)

The [list_records.rb](analytics_export_scripts/list_records.rb) shows latest records.
