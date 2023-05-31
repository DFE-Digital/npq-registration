[< Back to Navigation](../README.md)

# Importing Data

1. [Importing schools](#importing-schools)
1. [Importing Private Childcare Provider data](#importing-private-childcare-provider-data)
1. [Importing premium pupils data](#importing-premium-pupils-data)

## Importing schools

### Locally
- Open a rails console and run the following
- `Services::ImportGiasSchools.new.call`

### Production

This occurs automatically every night at 5am, through the [Sync School Data (Changed Schools Only)](.github/workflows/update_schools.yml) Github Action.

This detects which schools have had their data updated and then only updates those schools, it does this using the LastChangedDate column of the downloaded CSV to check for changes. 

#### Schools not updating
There is an edgecase that can occasionally lead to school data not updating when it should. This is due to the LastChangedDate column not being updated when a school has had their data updated multiple times in the same day as the column is a date and not a datetime. If a school changes once at 4am we would update the data at 5am and store the date of last change. If they then changed again at 12pm then the LastChangedDate would not update and we would not notice the change. If this occurs the school will not be updated until the next time their LastChangedDate changes. See below for how to update all schools.

#### Updating all schools
If you need to update all schools you can do this by running the (Sync School Data (All Schools))[.github/workflows/update_all_schools.yml] Github Action. This will ignore the LastChangedDate and perform a full school refresh.

## Importing Private Childcare Provider data

See [Acquiring New Private Childcare Provider data](docs/acquiring_new_private_childcare_provider_data.md) for how to acquire new data.

### Locally
- Open a rails console and run the following
- `bundle exec rake 'private_childcare_providers:import[lib/private_childcare_providers/2022-08-31/childcare_providers.csv,childcare_providers]'`
- `bundle exec rake 'private_childcare_providers:import[lib/private_childcare_providers/2022-08-31/childminder_agencies.csv,childminder_agencies]'`

### Production
There is no Github Action for this, the above rake tasks need to be called.

## Importing premium pupils data

### Locally
- Open a rails console and run the following
- `Services::SetHighPupilPremiums.new(path_to_csv: Rails.root.join("config/data/high_pupil_premiums_2021_2022.csv")).call`

### Production
There is no Github Action for this, the above rake tasks need to be called.
