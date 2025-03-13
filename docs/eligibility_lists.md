## NPQ Eligibility Lists

Currently, NPQ uses five eligibility lists, which are processed in a [own initializer](.././config/initializers/pp50_institutions.rb).  
The `pp50` designation refers to the 50% of UK schools receiving the highest pupil premium— extra funding provided for students from financially disadvantaged families.

### File Location

The lists are stored in the [config/data/January2025](.././config/data/January2025) directory.

## Eligibility Lists

### Schools PP50 List
**File:** `NPQ_Schools_PP50_2025_cohort.csv`
- Matches schools using the `urn` field.
- Schools are recorded in the `School` model.

### Further Education PP55 List
**File:** `NPQ_FE_PP50_2025_cohort.csv`
- Matches schools using the `ukprn` field.
- Schools are recorded in the `School` model.

### Childminders
**File:** `NPQ_EY_Childminders_2025_cohort.csv`
- Matches institutions using the `ofsted_urn` field.
- Institutions are recorded in the `PrivateChildcareProvider` model.

### Early Years Settings
**File:** `NPQ_Disadvantaged_EY_2025_cohort.csv`
- Matches institutions using both `urn` and `ofsted_urn` fields.
- Institutions are recorded in both the `School` and `PrivateChildcareProvider` models.
- The `ofsted_urn` field is used only when `urn` is empty.

### Local Authority Nurseries
**File:** `NPQ_LA_Nursery_Schools_2025_cohort.csv`
- Matches nurseries using the `urn` field.
- Nurseries are recorded in the `School` model.

## Updating the Lists

New lists should follow the same format as the existing ones.  
If the format changes, updates must be made to the [initializer](.././config/initializers/pp50_institutions.rb).