[< Back to Navigation](../README.md)

# BigQuery Reports

## Overview

Once an hour (at xx:00) the NPQ application exports all application data to BigQuery for analysis. 

This is handled by two Github Actions:
1. (Generate dashboard report)[.github/workflows/generate_dashboard_report.yml]
2. (Export dashboard report to BigQuery)[.github/workflows/export_dashboard_report.yml]

The first generates a CSV of all application data and stores it within the reports table. This generation occurs in `DashboardReportJob`. 

The second then exports this data to BigQuery, the extraction from the DB and push up is handeld within the action.
