# Submit, view and void declarations

Providers must submit declarations in line with NPQ contractual schedules and milestone dates [ADD LINK].

These declarations will trigger payment from DfE to providers.

When providers submit declarations, API response bodies will include data about which financial statement the given declaration applies to. Providers can then view financial statement payment dates [ADD LINK] to check when the invoicing period, and expected payment date, will be for the given declaration.

## Test the ability to submit declarations in sandbox ahead of time

```X-With-Server-Date``` is a custom JSON header supported in the sandbox environment. It lets providers test their integrations and ensure they are able to submit declarations for future milestone dates.

The ```X-With-Server-Date``` header lets providers simulate future dates, and therefore allows providers to test declaration submissions for future milestone dates.

> It's only valid in the sandbox environment. Attempts to submit future declarations in the production environment (or without this header in sandbox) will be rejected as part of milestone validation.

To test declaration submission functionality, include:

* the header ```X-With-Server-Date``` as part of declaration submission request
* the value of your chosen date in the ISO 8601 format with time and time zone (the RFC 3339 format). For example:
```X-With-Server-Date: 2022-01-10T10:42:00Z```

## Notify DfE a participant has started training

```
POST /api/v3/participant-declarations
```

Notify DfE a participant has started an NPQ course by submitting a ```started``` declaration in line with milestone 1 dates [ADD LINK].

Request bodies must include the necessary data attributes, including the ```declaration_type``` attribute with a started value.

Successful requests will return a response body with declaration data.

Any attempts to submit duplicate declarations will return an error message.

> Providers should store the returned NPQ participant declaration ID for management tasks.

For more detailed information, see the ```notify DfE that an NPQ participant has started training``` endpoint documentation [ADD LINK].

### Example ```request``` body

```
{
  "data": {
    "type": "participant-declaration",
    "attributes": {
      "participant_id": "db3a7848-7308-4879-942a-c4a70ced400a",
      "declaration_type": "started",
      "declaration_date": "2021-05-31T02:21:32.000Z",
      "course_identifier": "npq-leading-teaching"
    }
  }
}
```

### Example ```response``` body

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant-declaration",
    "attributes": {
      "participant_id": "bf3c6251-f2a0-4690-a859-0fbecc6ed151",
      "declaration_type": "started",
      "declaration_date": "2020-11-13T11:21:55Z",
      "course_identifier": "npq-leading-teaching",
      "state": "eligible",
      "updated_at": "2020-11-13T11:21:55Z",
      "created_at": "2020-11-13T11:21:55Z",
      "delivery_partner_id": null,
      "statement_id": "1cceffd7-0efd-432a-aedc-7be2d6cc72a2",
      "clawback_statement_id": null,
      "ineligible_for_funding_reason": null,
      "mentor_id": null,
      "uplift_paid": true,
      "evidence_held": null
      "has_passed": null
    }
  }
}
```

## Notify DfE a participant has been retained in training

```
POST /api/v{n}/participant-declarations
```

Notify DfE a participant has reached a given retention point in their course by submitting a ```retained``` declaration in line with milestone dates [ADD LINK].

Request bodies must include the necessary data attributes, including the appropriate ```declaration_type``` attribute value, for example ```retained-1```.

An example response body is listed below. Successful requests will return a response body with declaration data.

Any attempts to submit duplicate declarations will return an error message.

> Providers should store the returned NPQ participant declaration ID for management tasks.

For more detailed information see the specifications for this notify DfE that an NPQ participant has been retained in training endpoint [ADD LINK].

### Example ```request``` body

```
{
  “data”: {
    “type”: “participant-declaration”,
    “attributes”: {
      "participant_id": "db3a7848-7308-4879-942a-c4a70ced400a",
      "declaration_type": "retained-1",
      "declaration_date": "2021-05-31T02:21:32.000Z",
      "course_identifier": "npq-headship"
    }
  }
}
```

### Example ```response``` body

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant-declaration",
    "attributes": {
      "participant_id": "bf3c6251-f2a0-4690-a859-0fbecc6ed151",
      "declaration_type": "retained-1",
      "declaration_date": "2020-11-13T11:21:55Z",
      "course_identifier": "npq-headship",
      "state": "eligible",
      "updated_at": "2020-11-13T11:21:55Z",
      "created_at": "2020-11-13T11:21:55Z",
      "delivery_partner_id": null,
      "statement_id": "1cceffd7-0efd-432a-aedc-7be2d6cc72a2",
      "clawback_statement_id": null,
      "ineligible_for_funding_reason": null,
      "mentor_id": null,
      "uplift_paid": true,
      "evidence_held": null
      "has_passed": null
    }
  }
}
```

## Notify DfE a participant has completed training

```
POST /api/v{n}/participant-declarations
```

Notify DfE a participant has completed their course by submitting a ```completed``` declaration in line with milestone dates [ADD LINK].

You can do this for all NPQs and the Early headship coaching offer.

Request bodies must include the necessary data attributes, including the ```declaration_type``` attribute with a ```completed``` value, and the ```has_passed``` attribute with a ```true``` or ```false value```.

Successful requests will return a response body with declaration data.

Any attempts to submit duplicate declarations will return an error message.

> Providers should store the returned NPQ participant declaration ID for future management tasks.

For more detailed information, see the ```notify DfE that an NPQ participant has completed training``` endpoint documentation [ADD LINK].

### Example ```request``` body 

```
{
  “data”: {
    “type”: “participant-declaration”,
    “attributes”: {
      "participant_id": "db3a7848-7308-4879-942a-c4a70ced400a",
      "declaration_type": "completed",
      "declaration_date": "2021-05-31T02:21:32.000Z",
      "course_identifier": "npq-leading-teaching",
      "has_passed": true
    }
  }
}
```

### Example ```response``` body

```
{
 "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant-declaration",
    "attributes": {
      "participant_id": "db3a7848-7308-4879-942a-c4a70ced400a",
      "declaration_type": "completed",
      "declaration_date": "2021-05-31T02:21:32.000Z",
      "course_identifier": "npq-leading-teaching",
      "state": "eligible",
      "updated_at": "2020-11-13T11:21:55Z",
      "created_at": "2020-11-13T11:21:55Z",
      "delivery_partner_id": null,
      "statement_id": "1cceffd7-0efd-432a-aedc-7be2d6cc72a2",
      "clawback_statement_id": null,
      "ineligible_for_funding_reason": null,
      "mentor_id": null,
      "uplift_paid": true,
      "evidence_held": null
      "has_passed": true
    }
  }
}
```

## View all previously submitted declarations

```
GET /api/v3/participant-declarations
```

View all declarations which have been submitted to date. Check declaration submissions, identify if any are missing, and void or clawback those which have been submitted in error.

> Providers can also filter results by adding filters to the parameter. For example: ```GET /api/v3/participant-declarations?filter[participant_id]=ab3a7848-1208-7679-942a-b4a70eed400a``` or ```GET /api/v3/participant-declarations?filter[cohort]=2022&filter[updated_since]=2020-11-13T11:21:55Z```

For more detailed information see the specifications for this view all declarations endpoint [ADD LINK].

### Example ```response``` body:

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant-declaration",
    "attributes": {
      "participant_id": "bf3c6251-f2a0-4690-a859-0fbecc6ed151",
      "declaration_type": "started",
      "declaration_date": "2020-11-13T11:21:55Z",
      "course_identifier": "npq-leading-teaching",
      "state": "eligible",
      "updated_at": "2020-11-13T11:21:55Z",
      "created_at": "2020-11-13T11:21:55Z",
      "delivery_partner_id": null,
      "statement_id": "1cceffd7-0efd-432a-aedc-7be2d6cc72a2",
      "clawback_statement_id": null,
      "ineligible_for_funding_reason": null,
      "mentor_id": null,
      "uplift_paid": true,
      "evidence_held": null
      "has_passed": null
    }
  }
}
```

## View a specific previously submitted declaration

```
GET /api/v3/participant-declarations/{id}
```

View a specific declaration which has been previously submitted. Check declaration details and void or clawback those which have been submitted in error.

For more detailed information, see the ```view specific declarations``` endpoint documentation [ADD LINK].

### Example ```response``` body:

{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant-declaration",
    "attributes": {
      "participant_id": "bf3c6251-f2a0-4690-a859-0fbecc6ed151",
      "declaration_type": "started",
      "declaration_date": "2020-11-13T11:21:55Z",
      "course_identifier": "npq-leading-teaching",
      "state": "eligible",
      "updated_at": "2020-11-13T11:21:55Z",
      "created_at": "2020-11-13T11:21:55Z",
      "delivery_partner_id": null,
      "statement_id": "1cceffd7-0efd-432a-aedc-7be2d6cc72a2",
      "clawback_statement_id": null,
      "ineligible_for_funding_reason": null,
      "mentor_id": null,
      "uplift_paid": true,
      "evidence_held": null
      "has_passed": null
    }
  }
}

## Void or clawback a declaration

```
PUT /api/v3/participant-declarations/{id}/void
```

Void specific declarations which have been submitted in error.

Successful requests will return a response body including updates to the declaration ```state```, which will become:

* ```voided``` if it had been ```submitted```, ```ineligible```, ```eligible```, or ```payable```
* ```awaiting_clawback``` if it had been paid

View more information on declaration states [HYPERLINK]

> If a provider voids a ```completed``` declaration, the outcome (indicating whether they have passed or failed) will be retracted. The ```has_passed``` value will revert to ```null```.

For more detailed information, see the ```void declarations``` endpoint documentation [ADD LINK].

### Example ```response``` body

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "participant-declaration",
    "attributes": {
      "participant_id": "bf3c6251-f2a0-4690-a859-0fbecc6ed151",
      "declaration_type": "completed",
      "declaration_date": "2020-11-13T11:21:55Z",
      "course_identifier": "npq-leading-teaching",
      "state": "voided",
      "updated_at": "2020-11-13T11:21:55Z",
      "created_at": "2020-11-13T11:21:55Z",
      "delivery_partner_id": null,
      "statement_id": "1cceffd7-0efd-432a-aedc-7be2d6cc72a2",
      "clawback_statement_id": null,
      "ineligible_for_funding_reason": null,
      "mentor_id": null,
      "uplift_paid": true,
      "evidence_held": null
      "has_passed": null
    }
  }
}
```