# Submit, view and void declarations

Providers must submit declarations in line with NPQ contractual schedules and milestone dates.

These declarations will trigger payment from DfE to providers.

When providers submit declarations, API response bodies will include data about which financial statement the given declaration applies to. Providers can then view financial statement payment dates to check when the invoicing period, and expected payment date, will be for the given declaration.

## Test that you can submit declarations ahead of time

`X-With-Server-Date` is a custom JSON header supported in the test environment. It lets providers test their integrations and ensure they're able to submit declarations for future milestone dates.

The `X-With-Server-Date` header lets providers simulate future dates, and therefore allows providers to test declaration submissions for future milestone dates.

<div class="govuk-inset-text">
  It's only valid in the test environment. Attempts to submit future declarations in the production environment (or without this header in the test environment) will be rejected as part of milestone validation.
</div>

To test declaration submission functionality, include:

* the header `X-With-Server-Date` as part of declaration submission request
* the value of your chosen date in the ISO 8601 format with time and time zone (the RFC 3339 format). For example:

```
X-With-Server-Date: 2022-01-10T10:42:00Z
```

## Declare a participant has reached a milestone

```
POST /api/v3/participant-declarations
```

Notify DfE a participant has started an NPQ course by submitting a `started` declaration in line with milestone 1 dates.

Request bodies must include the necessary data attributes, including the `declaration_type` attribute with a started value.

Successful requests will return a response body with declaration data.

Any attempts to submit duplicate declarations will return an error message.

<div class="govuk-inset-text">
  Providers should store the returned NPQ participant declaration ID for management tasks.
</div>

For more detailed information, see the ['Declare a participant has reached a milestone' endpoint documentation](/api/docs/v3#/Participant%20declarations/post_api_v3_participant_declarations).

### Example request body

```json
{
  "data": {
    "type": "participant-declaration",
    "attributes": {
      "participant_id": "db3a7848-7308-4879-942a-c4a70ced400a",
      "declaration_type": "started",
      "declaration_date": "2021-05-31T02:21:32.000Z",
      "course_identifier": "npq-senior-leadership"
    }
  }
}
```

### Example response body

```json
{
  "data": {
    "id": "d0b4a32e-a272-489e-b30a-cb17131457fc",
    "type": "participant-declaration",
    "attributes": {
      "participant_id": "db3a7848-7308-4879-942a-c4a70ced400a",
      "declaration_type": "started",
      "course_identifier": "npq-senior-leadership",
      "declaration_date": "2022-04-30",
      "state": "submitted",
      "has_passed": null,
      "statement_id": null,
      "clawback_statement_id": null,
      "uplift_paid": true,
      "lead_provider_name": "Example Institute",
      "ineligible_for_funding_reason": "duplicate_declaration",
      "created_at": "2021-05-31T02:22:32.000Z",
      "updated_at": "2021-05-31T02:22:32.000Z"
    }
  }
}
```

## Retrieve multiple participant declarations

```
GET /api/v3/participant-declarations
```

Use this endpooint to: 

* view all declarations which have been submitted to date
* check declaration submissions
* identify if any are missing
* void or clawback declarations which have been submitted in error

Providers can also filter results by adding filters to the parameter. For example: `GET /api/v3/participant-declarations?filter[participant_id]=ab3a7848-1208-7679-942a-b4a70eed400a` or `GET /api/v3/participant-declarations?filter[cohort]=2022&filter[updated_since]=2020-11-13T11:21:55Z`

For more detailed information, see the ['Retrieve multiple participant declarations' endpoint documentation](/api/docs/v3#/Participant%20declarations/get_api_v3_participant_declarations).

### Example response body

```json
{
  "data": [
    {
      "id": "d0b4a32e-a272-489e-b30a-cb17131457fc",
      "type": "participant-declaration",
      "attributes": {
        "participant_id": "db3a7848-7308-4879-942a-c4a70ced400a",
        "declaration_type": "started",
        "course_identifier": "npq-senior-leadership",
        "declaration_date": "2022-04-30",
        "state": "submitted",
        "has_passed": null,
        "statement_id": null,
        "clawback_statement_id": null,
        "uplift_paid": true,
        "lead_provider_name": "Example Institute",
        "ineligible_for_funding_reason": "duplicate_declaration",
        "created_at": "2021-05-31T02:22:32.000Z",
        "updated_at": "2021-05-31T02:22:32.000Z"
      }
    }
  ]
}
```

## Retrieve a single participant’s declarations

```
GET /api/v3/participant-declarations/{id}
```

View a specific declaration which has been previously submitted. Check declaration details and void or clawback those which have been submitted in error.

For more detailed information, see the ['Retrieve a single participant’s declarations' endpoint documentation](/api/docs/v3#/Participant%20declarations/get_api_v3_participant_declarations__id_).

### Example response body

```json
{
  "data": {
    "id": "d0b4a32e-a272-489e-b30a-cb17131457fc",
    "type": "participant-declaration",
    "attributes": {
      "participant_id": "db3a7848-7308-4879-942a-c4a70ced400a",
      "declaration_type": "started",
      "course_identifier": "npq-senior-leadership",
      "declaration_date": "2022-04-30",
      "state": "submitted",
      "has_passed": null,
      "statement_id": null,
      "clawback_statement_id": null,
      "uplift_paid": true,
      "lead_provider_name": "Example Institute",
      "ineligible_for_funding_reason": "duplicate_declaration",
      "created_at": "2021-05-31T02:22:32.000Z",
      "updated_at": "2021-05-31T02:22:32.000Z"
    }
  }
}
```

## Void a declaration

```
PUT /api/v3/participant-declarations/{id}/void
```

Void specific declarations which have been submitted in error.

Successful requests will return a response body including updates to the declaration `state`, which will become:

* `voided` if it had been `submitted`, `ineligible`, `eligible`, or `payable`
* `awaiting_clawback` if it had been paid

If a provider voids a `completed` declaration, the outcome (indicating whether they have passed or failed) will be retracted. The `has_passed` value will revert to `null`.

For more detailed information, see the ['Void a declaration' endpoint documentation](/api/docs/v3#/Participant%20declarations/put_api_v3_participant_declarations__id__void).

### Example response body

```json
{
  "data": {
    "id": "d0b4a32e-a272-489e-b30a-cb17131457fc",
    "type": "participant-declaration",
    "attributes": {
      "participant_id": "db3a7848-7308-4879-942a-c4a70ced400a",
      "declaration_type": "started",
      "course_identifier": "npq-senior-leadership",
      "declaration_date": "2022-04-30",
      "state": "voided",
      "has_passed": null,
      "statement_id": "cd3a12347-7308-4879-942a-c4a70ced400a",
      "clawback_statement_id": null,
      "uplift_paid": true,
      "lead_provider_name": "Example Institute",
      "ineligible_for_funding_reason": "duplicate_declaration",
      "created_at": "2021-05-31T02:22:32.000Z",
      "updated_at": "2021-05-31T02:22:32.000Z"
    }
  }
}
```
