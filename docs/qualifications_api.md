[< Back to Navigation](../README.md)

# Qualifications API

## Overview

The Teaching Regulation Agency (TRA) has decommissioned the Database of Qualified Teachers (DQT) that held NPQ qualifications data. The replacement Teacher Record Service (TRS) will not include NPQ qualification data.

NPQ Registration has an API that replaces this: the Qualifications API.

This returns NPQ qualifications for a given user, based upon their Teacher Reference Number (TRN).
It returns both qualifications that are currently held in NPQ registration and those that were previously stored in DQT.

## API usage

To get qualifications for a TRN:

`GET /api/teacher-record-service/v1/qualifications/1000207`

Example response:

``` json
{"data":
  {"trn":"1000207",
   "qualifications":[
    {"award_date":"2023-10-01","npq_type":"NPQEYL"},
    {"award_date":"2023-10-01","npq_type":"NPQSL"},
    {"award_date":"2021-10-01","npq_type":"NPQLBC"},
    {"award_date":"2021-10-01","npq_type":"NPQSENCO"},
    {"award_date":"2020-10-01","npq_type":"NPQSL"}
  ]
 }
}
```
> note: there can be multiple passed qualifications for the same npq_type (in the above example, NPQSL has been passed twice).

If no qualifications are found for the TRN, the response will be:

``` json
{"data":
  {"trn":"1000207",
   "qualifications":[]
 }
}
```

## Authentication

This API uses bearer token authentication. The bearer token is passed in the `Authorization` header:
```
Authorization: Bearer <token>
```
