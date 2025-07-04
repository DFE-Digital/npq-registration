[< Back to Navigation](../README.md)

# Acquiring new Private Childcare Provider CSV data for import

1. [Overview](#overview)
1. [Acquiring the CSV files](#acquiring-the-csv-files)
1. [Extracting the data](#extracting-the-data)
1. [Importing the data](../docs/importing_data.md#importing-private-childcare-provider-data)

## Overview

Private Childcare Provider data is acquired twice a year from Ofsted. The data is used to populate the `private_childcare_provider` table in the database through the `import_private_childcare_providers` rake task.

This data is provided by Ofsted as CSV files. The CSV files need to be amended to remove non-header rows before they can be imported into the database.

## Acquiring the CSV files

The CSV files are released on the GOV.uk statistics pages, and can be found at: https://www.gov.uk/government/statistical-data-sets/childcare-providers-and-inspections-management-information
The latest files (as of February 2025) are December 2024 data, which was released January 2025.

## Amend the CSV files

Download from the above link the CSV files named:
- `Management information - childcare providers and inspections - most recent inspections data as at 31 December 2024`
- rename this file to `childcare_providers.csv`
- `Management information - childcare providers and inspections - registered childminder agencies as at 31 December 2024`
- reame this file to childminder_agencies.csv
- delete the non-header rows from the files - the first line should be the CSV header

As the exact structure of these files can differ year to year it is worth running these files through the import process locally to ensure the data is being imported correctly before committing the files to the repository. Any changes would mean that the [import rake task](../lib/tasks/private_childcare_providers.rake) would need to be updated to reflect the new structure, these changes would be made in the CSV row wrapper classes:
- [Importers::ImportPrivateChildcareProviders::ChildcareProviderWrappedCSVRow](../app/services/importers/import_private_childcare_providers.rb)
- [Importers::ImportPrivateChildcareProviders::ChildminderAgencyWrappedCSVRow](../app/services/importers/import_private_childcare_providers.rb)
