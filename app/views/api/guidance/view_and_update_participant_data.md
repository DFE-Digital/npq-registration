# View and update participant data

Once a provider has accepted an application, they can **view and update data** to notify DfE that a participant has:

* deferred their course [Add link to 'deferred' section]
* resumed their course [Add link to 'resumed' section]
* withdrawn from their course [Add link to 'withdrawn' section]
* changed their course schedule [Add link to 'changed course schedule' section]
* an updated course outcome [Add link to 'updated course outcome' section]

## View all participant data

```
GET /api/v3/participants/npq
```

<div class="govuk-inset-text">
Providers can **filter results** by adding `updated_since` filters to the parameter. For example: `GET /api/v{n}/participants/ecf?filter[updated_since]=2020-11-13T11:21:55Z`
</div>

### Check for participant ID changes

Providers can check if an NPQ participant’s ID has changed using the `participant_id_changes` nested structure in the NPQEnrolment [ADD LINK], which contains a `from_participant_id` and a `to_participant_id` string fields, as well a `changed_at` date value.

### Duplicate IDs 

We've previously advised [ADD LINK] of the possibility that participants may be registered as duplicates with multiple participant IDs. Where we identify duplicates, we'll fix the error by ‘retiring’ one of the participant IDs, then associating all records and data under the remaining ID.

For more detailed information, see the ```view multiple NPQ participants``` endpoint documentation [ADD LINK].

### Example ```response``` body

```
{
  "data": [
    {
      "id": "ac3d1243-7308-4879-942a-c4a70ced400a",
      "type": "npq-participant",
      "attributes": {
        "full_name": "Isabelle MacDonald",
        "teacher_reference_number": "1234567",
        "updated_at": "2021-05-31T02:22:32.000Z",
        "npq_enrolments": [
          {
            "email": "isabelle.macdonald2@some-school.example.com",
            "course_identifier": "npq-senior-leadership",
            "schedule_identifier": "npq-leadership-autumn",
            "cohort": "2021",
            "npq_application_id": "db3a7848-7308-4879-942a-c4a70ced400a",
            "eligible_for_funding": true,
            "training_status": "active",
            "school_urn": "123456",
            "targeted_delivery_funding_eligibility": true,
            "withdrawal": null
            "deferral": null
            "created_at": "2021-05-31T02:22:32.000Z"
          }
        ],
        "participant_id_changes": [
          {
            "from_participant_id": "ac3d1243-7308-4879-942a-c4a70ced400a",
            "to_participant_id": "23dd8d66-e11f-4139-9001-86b4f9abcb02",
            "changed_at": "2023-09-23T02:22:32.000Z",
          }
        ]
      }
    }
  ]
}
```

## View a single participant’s data

```
GET /api/v3/participants/npq/{id}
```

### Check for participant ID changes

Providers can check if an NPQ participant’s ID has changed using the `participant_id_changes` nested structure in the NPQEnrolment [AD LINK], which contains a `from_participant_id` and a `to_participant_id` string fields, as well a `changed_at` date value.

### Duplicate IDs 

We've previously advised [ADD LINK] of the possibility that participants may be registered as duplicates with multiple participant IDs. 

Where we identify duplicates, we'll fix the error by ‘retiring’ one of the participant IDs, then associating all records and data under the remaining ID. 

To date, when this has occurred, we’ve informed providers of changes via CSVs

For more detailed information, see the ```view multiple NPQ participants``` endpoint documentation [ADD LINK].

### Example ```response``` body

```
{
  "data": [
    {
      "id": "ac3d1243-7308-4879-942a-c4a70ced400a",
      "type": "npq-participant",
      "attributes": {
        "full_name": "Isabelle MacDonald",
        "teacher_reference_number": "1234567",
        "updated_at": "2021-05-31T02:22:32.000Z",
        "npq_enrolments": [
          {
            "email": "isabelle.macdonald2@some-school.example.com",
            "course_identifier": "npq-senior-leadership",
            "schedule_identifier": "npq-leadership-autumn",
            "cohort": "2021",
            "npq_application_id": "db3a7848-7308-4879-942a-c4a70ced400a",
            "eligible_for_funding": true,
            "training_status": "active",
            "school_urn": "123456",
            "targeted_delivery_funding_eligibility": true,
            "withdrawal": null
            "deferral": null
            "created_at": "2021-05-31T02:22:32.000Z"
          }
        ],
        "participant_id_changes": [
          {
            "from_participant_id": "ac3d1243-7308-4879-942a-c4a70ced400a",
            "to_participant_id": "23dd8d66-e11f-4139-9001-86b4f9abcb02",
            "changed_at": "2023-09-23T02:22:32.000Z",
          }
        ]
      }
    }
  ]
}
```

## Notify DfE a participant has deferred their training

```
PUT /api/v{n}/participants/npq/{id}/defer
```

A participant can choose to **defer** their course at any time if they plan to resume training at a later date. Providers must notify DfE of this via the API.

Successful requests will return a response body including updates to the ```training_status``` attribute.

For more detailed information, see the ```notify DfE that an NPQ participant is taking a break from their course``` endpoint documentation [ADD LINK].

### Example ```request``` body

```
{
  "data": {
    "type": "participant-defer",
    "attributes": {
      "reason": "parental-leave",
      "course_identifier": "npq-senior-leadership"
    }
  }
}
```

## Notify DfE a participant has resumed training

```
PUT /api/v3/participants/npq/{id}/resume
```

A participant can **resume** their course at any time if they've previously deferred. Providers must notify DfE of this via the API.

Successful requests will return a response body including updates to the ```training_status``` attribute.

For more detailed information, see the ```notify DfE that an NPQ participant has resumed training``` endpoint documentation [ADD LINK].

### Example ```request``` body

```
{
  "data": {
    "type": "participant-resume",
    "attributes": {
      "course_identifier": "npq-leading-teaching-development"
    }
  }
}
```

## Notify DfE a participant has withdrawn from training

```
PUT /api/v3/participants/npq/{id}/withdraw
```

A participant can choose to **withdraw** from their course at any time. Providers must notify DfE of this via the API.

Successful requests will return a response body including updates to the ```training_status``` attribute, and a withdrawal ```date``` reflecting the time the provider submitted the withdrawal API request.

Providers should note that:

* the API will not allow withdrawals for participants who've not had a started declaration submitted against them. If a participant withdraws before a started declaration has been submitted, providers should speak to their contract manager for further advice
* we'll only pay for participants who have had, at a minimum, a started declaration submitted against them
* if a participant is withdrawn later in their course, we'll pay providers for any declarations submitted where the ```declaration_date``` is before the withdrawal date
* the amount we'll pay depends on which milestones have been reached with declarations submitted before withdrawal

For more detailed information, see the ```notify DfE that an NPQ participant has withdrawn from training``` endpoint documentation [ADD LINK].

### Example ```request``` body

```
{
  "data": {
    "type": "participant-withdraw",
    "attributes": {
      "reason": "quality-of-programme-other",
      "course_identifier": "npq-leading-teaching-development"
    }
  }
}
```

## Notify DfE a participant has changed their training schedule

```
PUT /api/v3/participants/npq/{id}/change-schedule
```

The API will automatically assign schedules to participants depending on when course applications are accepted by providers. Providers must notify DfE of any **schedule change**.

Successful requests will return a response body including updates to the ```schedule_identifier``` attribute.

### What if the declaration date and new schedule's milestone dates do not align? 

The API will reject a schedule change if any submitted, eligible, payable or paid declarations have a ```declaration_date``` which does not align with the new schedule’s milestone dates. 

For example, a participant is in the 2023 cohort on an ```npq-specialist-autumn``` schedule. Their provider has submitted a started declaration dated 1 October 2023. The provider tries to change the schedule to ```npq-specialist-spring```. The API will reject the change because a spring schedule does not start until January, which is after the declaration date. The API returns an error message with instructions to void existing declarations first.

For more detailed information, see the ```notify that an NPQ participant has changed their training schedule``` endpoint documentation [ADD LINK].

### Example ```request``` body

```
{
  "data": {
    "type": "participant-change-schedule",
    "attributes": {
      "schedule_identifier": "npq-leadership-autumn",
      "course_identifier": "npq-leading-teaching",
      "cohort": "2021"
    }
  }
}
```

## View all participant outcomes

```
GET /api/v3/participants/npq/outcomes
```

Participants can either pass or fail assessment at the end of their NPQ course. These outcomes are submitted by providers within ```completed``` declaration submissions.

<div class="govuk-inset-text">
Outcomes are sent to the Database of Qualified Teachers (DQT). They issue certificates to participants who've passed.
</div>

Successful requests will return a response body including an outcome ```state``` value to signify:

* outcomes submitted (```passed``` or ```failed```)
* if ```completed``` declarations have been voided and the outcome retracted (```voided```)

For more detailed information, see the ```view NPQ outcomes``` endpoint documentation [ADD LINK].

### Example ```response``` body

```
{
  "data": [
    {
      "id": "cd3a12347-7308-4879-942a-c4a70ced400a",
      "type": "participant-outcome",
      "attributes": {
        "participant_id": "66218835-9430-4d0c-98ef-7caf0bb4a59b",
        "course_identifier": "npq-leading-teaching",
        "state": "passed",
        "completion_date": "2021-05-31T00:00:00+00:00",
        "created_at": "2021-05-31T02:21:32.000Z",
        "updated_at": "2021-05-31T02:21:32.000Z"
      }
    }
  ]
}
```

## View a specific participant’s outcome

```
GET /api/v3/participants/npq/{participant_id}/outcomes
```

A participant can either pass or fail assessment at the end of their NPQ course. Their outcome will be submitted by providers within ```completed``` declaration submissions.

<div class="govuk-inset-text">
Outcomes are sent to the Database of Qualified Teachers (DQT). They issue certificates to participants who've passed.
</div>

Successful requests will return a response body including an outcome ```state``` value to signify:

* the outcome submitted (```passed``` or ```failed```)
* if the ```completed``` declaration has been ```voided``` and the outcome retracted (```voided```)

For more detailed information, see the ```view NPQ outcome for a specific participant``` endpoint documentation [ADD LINK].

### Example ```response``` body

```
{
  "data": [
    {
      "id": "cd3a12347-7308-4879-942a-c4a70ced400a",
      "type": "participant-outcome",
      "attributes": {
        "participant_id": "66218835-9430-4d0c-98ef-7caf0bb4a59b",
        "course_identifier": "npq-leading-teaching",
        "state": "passed",
        "completion_date": "2021-05-31T00:00:00+00:00",
        "created_at": "2021-05-31T02:21:32.000Z",
        "updated_at": "2021-05-31T02:21:32.000Z"
      }
    }
  ]
}
```

## Update a participant’s outcomes

```
POST /api/v1/participant/npq/{participant_id}/outcomes
```

Outcomes may need to be updated if previously submitted data was inaccurate. For example, a provider should update a participant’s outcome if:

* the reported outcome was incorrect
* the reported date the participant received their outcome was incorrect
* a participant has retaken their NPQ assessment and their outcome has changed

Request bodies must include a new value for the outcome ```state``` and ```completion_date```.

Successful requests will return a response body with updates included.

For more detailed information, see the ```update an NPQ outcome``` endpoint documentation [ADD LINK].

### Example ```request``` body

```
{
  "data": {
    "type": "npq-outcome-confirmation",
    "attributes": {
      "course_identifier": "npq-leading-teaching",
      "state": "passed",
      "completion_date": "2021-05-31"
    }
  }
}
```