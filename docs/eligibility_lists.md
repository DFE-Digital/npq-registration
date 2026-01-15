## NPQ Eligibility Lists

Currently, NPQ uses five eligibility lists, which are loaded from CSV files into the admin console, in the Workplaces tab.

The `PP50` designation refers to the 50% of UK schools receiving the highest pupil premium — extra funding provided for students from financially disadvantaged families.

## Eligibility Lists

The CSV files can have as many extra columns as you like, but they must have the required identifier column as specified below.

### PP50 Schools List
- Header: `PP50 School URN`

### PP50 FE (Further Education) List
- Header: `FE UKPRN`

### Childminders List
- Header: `Childminder URN`

### Disadvantaged EY (Early Years) List
- Header: `Disadvantaged EY School URN, Ofsted URN`

If a school does not have an Ofsted URN, then the Disadvantaged EY School URN will be used.

### LA (Local Authority) Nurseries List
- Header: `LA Nursery URN`

### RISE (Regional improvement for standards and excellence) List
- Header: `RISE School URN`
