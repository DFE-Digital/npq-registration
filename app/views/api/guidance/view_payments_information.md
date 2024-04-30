# View payments information 

> The following endpoints are only available for systems integrated with API v3 onwards. They will not return data for API v1 or v2.

Providers can view up to date payment cut-off dates, upcoming payment dates, and check to see whether output payments have been made by DfE.

## View all statement payment dates

```
GET /api/v3/statements
```

For more detailed information, see the ```view all statements``` endpoint documentation [ADD LINK].

### Example ```response``` body

```
{
  "data": [
    {
      "id": "cd3a12347-7308-4879-942a-c4a70ced400a",
      "type": "statement",
      "attributes": {
        "month": "May",
        "year": "2022",
        "type": "npq",
        "cohort": "2021",
        "cut_off_date": "2022-04-30",
        "payment_date": "2022-05-25",
        "paid": true,
        "created_at": "2021-05-31T02:22:32.000Z",
        "updated_at": "2021-05-31T02:22:32.000Z"
      }
    }
  ]
}
```

## View specific statement payment dates

```
GET /api/v3/statements/{id}
```

Providers can find statement IDs within previously submitted declaration response bodies.

For more detailed information see, the ```view a specific statement``` endpoint documentation [ADD LINK].

### Example ```response``` body

```
{
  "data": {
    "id": "cd3a12347-7308-4879-942a-c4a70ced400a",
    "type": "statement",
    "attributes": {
      "month": "May",
      "year": "2022",
      "type": "npq",
      "cohort": "2021",
      "cut_off_date": "2022-04-30",
      "payment_date": "2022-05-25",
      "paid": true,
      "created_at": "2021-05-31T02:22:32.000Z",
      "updated_at": "2021-05-31T02:22:32.000Z"
    }
  }
}
```