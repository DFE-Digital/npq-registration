## NPQ Eligibility Lists

Currently, NPQ uses five eligibility lists, which are processed in [an initializer](.././config/initializers/pp50_institutions.rb).

The `pp50` designation refers to the 50% of UK schools receiving the highest pupil premium — extra funding provided for students from financially disadvantaged families.

### File Location

The lists are stored in the [config/data/January2025](.././config/data/January2025) directory.

## Eligibility Lists

Lists are processed and saved to a constant. Each constant is a hash where key is the institution identification number and value is always true. The hash is used for fast and simple lookup.
The constants are used in the methods called by the `FundingEligiblity` calculator.

Example method using this list:

```ruby
def ey_eligible?
  !!EY_OFSTED_URN_HASH[urn.to_s] || !!PP50_SCHOOLS_URN_HASH[urn.to_s]
end

```

### Schools PP50 List
**File:** `NPQ_Schools_PP50_2025_cohort.csv`
- Matches schools using the `urn` field from the document.
- Schools are instances of the `School` model.
- Uses `PP50_SCHOOLS_URN_HASH` for lookup in the code.

### Further Education PP55 List
**File:** `NPQ_FE_PP50_2025_cohort.csv`
- Matches schools using the `ukprn` field from the document.
- Schools are instances of the `School` model.
- Uses `PP50_FE_UKPRN_HASH` for lookup in the code.

### Early Years Settings
**File:** `NPQ_Disadvantaged_EY_2025_cohort.csv`
- Matches institutions using both `urn` and `ofsted_urn` fields from the document.
- The `ofsted_urn` field is used only when `urn` is empty.
- Institutions are instances of the `School` and `PrivateChildcareProvider` models.
- Uses `EY_OFSTED_URN_HASH` for lookup in the code.

### Local Authority Nurseries
**File:** `NPQ_LA_Nursery_Schools_2025_cohort.csv`
- Matches nurseries using the `urn` field from the document.
- Nurseries are instances of the `School` model.
- Uses `LA_DISADVANTAGED_NURSERIES` for lookup in the code.

## Updating the Lists

New lists should follow the same format as the existing ones.
If the format changes, updates must be made to the [initializer](.././config/initializers/pp50_institutions.rb).
