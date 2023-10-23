[< Back to Navigation](../README.md)

# Acquiring new Private Childcare Provider CSV data for import

1. [Overview](#overview)
1. [Acquiring the ODS files](#acquiring-the-ods-files)
1. [Extracting the data](#extracting-the-data)
1. [Importing the data](../docs/importing_data.md#importing-private-childcare-provider-data)

## Overview

Private Childcare Provider data is acquired twice a year from Ofsted. The data is used to populate the `private_childcare_provider` table in the database through the `import_private_childcare_providers` rake task.

This data is provided by Ofsted as ODS files, the data within these needs extracting and transforming into a CSV file that can be imported into the database.

## Acquiring the ODS files

The ODS files are released on the GOV.uk statistics pages, upcoming releases for 2023 can be found at:
- [March 2023 data, released June 2023](https://www.gov.uk/government/statistics/announcements/childcare-providers-and-inspections-as-at-31-march-2023)
- [August 2023 data, released November 2023](https://www.gov.uk/government/statistics/announcements/childcare-providers-and-inspections-as-at-31-august-2023)

Files past 2023 can be found by searching for similarly named pages on GOV.uk, for example past data was available at, [March 2022, released June 2022](https://www.gov.uk/government/statistics/childcare-providers-and-inspections-as-at-31-march-2022).

## Extracting the data

Downloading the file named `Childcare provider level data as at 31 March 2022` at the above link for March 2022 provides an ODS file containing five sheets:
- Cover
- Notes
- Data_dictionary
- D1-_Childcare_providers
- D2-_Childminder_Agency
- D3-_Providers_left_EYR

We care about two of these sheets, `D1-_Childcare_providers` and `D2-_Childminder_Agency`. Extracting these two files to CSV files and stripping out the non-data rows gives us two CSV files that can be imported into the database.

As the exact structure of these files can differ year to year it is worth running these files through the import process locally to ensure the data is being imported correctly before committing the files to the repository. Any changes would mean that the [import rake task](../lib/tasks/private_childcare_providers.rake) would need to be updated to reflect the new structure, these changes would be made in the CSV row wrapper classes:
- [PrivateChildcareProviders::Importer::ChildcareProviderWrappedCSVRow](../app/lib/services/private_childcare_providers/importer.rb)
- [PrivateChildcareProviders::Importer::ChildminderAgencyWrappedCSVRow](../app/lib/services/private_childcare_providers/importer.rb)
