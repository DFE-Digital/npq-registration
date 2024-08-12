# View and update participant data

Once a provider has accepted an application, they can **view and update data** to notify DfE that a participant has:

* deferred their course
* resumed their course
* withdrawn from their course
* changed their course schedule
* an updated course outcome

## Retrieve multiple participants

```
GET /api/v3/participants/npq
```

<div class="govuk-inset-text">
Providers can filter results by adding updated_since filters to the parameter. For example: <code>GET /api/v{n}/participants/ecf?filter[updated_since]=2020-11-13T11:21:55Z</code>
</div>

### Check for participant ID changes

Providers can check if an NPQ participant’s ID has changed using the `participant_id_changes` nested structure in the `NPQEnrolment`, which contains a `from_participant_id` and a `to_participant_id` string fields, as well a `changed_at` date value.

### Duplicate IDs 

We've [previously advised](https://manage-training-for-early-career-teachers.education.gov.uk/api-reference/release-notes.html#15-march-2023) of the possibility that participants may be registered as duplicates with multiple participant IDs. Where we identify duplicates, we'll fix the error by ‘retiring’ one of the participant IDs, then associating all records and data under the remaining ID.

For more detailed information, see the ['Retrieve multiple participants' endpoint documentation](/api/docs/v3#/NPQ%20Participants/get_api_v3_participants_npq).

### Example response body

```json
{
  "data": [
    {
      "id": "d0b4a32e-a272-489e-b30a-cb17131457fc",
      "type": "npq-participant",
      "attributes": {
        "full_name": "Isabelle MacDonald",
        "teacher_reference_number": "1234567",
        "updated_at": "2021-05-31T02:22:32.000Z",
        "npq_enrolments": [
          {
            "email": "isabelle.macdonald2@some-school.example.com",
            "course_identifier": "npq-senior-leadership",
            "schedule_identifier": "npq-aso-march",
            "cohort": "2022",
            "npq_application_id": "db3a7848-7308-4879-942a-c4a70ced400a",
            "eligible_for_funding": true,
            "training_status": "active",
            "school_urn": "106286",
            "targeted_delivery_funding_eligibility": true,
            "withdrawal": null,
            "deferral": null,
            "created_at": "2021-05-31T02:21:32.000Z",
            "funded_place": true
          }
        ],
        "participant_id_changes": [
          {
            "from_participant_id": "23dd8d66-e11f-4139-9001-86b4f9abcb02",
            "to_participant_id": "ac3d1243-7308-4879-942a-c4a70ced400a",
            "changed_at": "2021-05-31T02:22:32.000Z"
          }
        ]
      }
    }
  ]
}
```

## Retrieve a single participant’s data

```
GET /api/v3/participants/npq/{id}
```

### Check for participant ID changes

Providers can check if an NPQ participant’s ID has changed using the `participant_id_changes` nested structure in the `NPQEnrolment`, which contains a `from_participant_id` and a `to_participant_id` string fields, as well a `changed_at` date value.

### Duplicate IDs 

We've [previously advised](https://manage-training-for-early-career-teachers.education.gov.uk/api-reference/release-notes.html#15-march-2023) of the possibility that participants may be registered as duplicates with multiple participant IDs. Where we identify duplicates, we'll fix the error by ‘retiring’ one of the participant IDs, then associating all records and data under the remaining ID.

Where we identify duplicates, we'll fix the error by ‘retiring’ one of the participant IDs, then associating all records and data under the remaining ID. 

To date, when this has occurred, we’ve informed providers of changes via CSVs

For more detailed information, see the ['Retrieve a single participant' endpoint documentation](/api/docs/v3#/NPQ%20Participants/get_api_v3_participants_npq__id_).

### Example response body

```json
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
            "funded_place": true,
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

## Defer a particpant

```
PUT /api/v3/participants/npq/{id}/defer
```

A participant can choose to **defer** their course at any time if they plan to resume training at a later date. Providers must notify DfE of this via the API.

Successful requests will return a response body including updates to the `training_status` attribute.

For more detailed information, see the ['Defer a participant' endpoint documentation](/api/docs/v3#/NPQ%20Participants/put_api_v3_participants_npq__id__defer).

### Example request body

```json
{
  "data": {
    "type": "participant-defer",
    "attributes": {
      "course_identifier": "npq-senior-leadership",
      "reason": "bereavement"
    }
  }
}
```

## Resume a participant

```
PUT /api/v3/participants/npq/{id}/resume
```

A participant can **resume** their course at any time if they've previously deferred. Providers must notify DfE of this via the API.

Successful requests will return a response body including updates to the `training_status` attribute.

For more detailed information, see the ['Resume a participant' endpoint documentation](/api/docs/v3#/NPQ%20Participants/put_api_v3_participants_npq__id__resume).

###Example request body

```json
{
  "data": {
    "type": "participant-resume",
    "attributes": {
      "course_identifier": "npq-senior-leadership"
    }
  }
}
```

## Withdraw a participant

```
PUT /api/v3/participants/npq/{id}/withdraw
```

A participant can choose to **withdraw** from their course at any time. Providers must notify DfE of this via the API.

Successful requests will return a response body including updates to the `training_status` attribute, and a withdrawal `date` reflecting the time the provider submitted the withdrawal API request.

Providers should note that:

* the API will not allow withdrawals for participants who've not had a started declaration submitted against them. If a participant withdraws before a started declaration has been submitted, providers should speak to their contract manager for further advice
* we'll only pay for participants who have had, at a minimum, a started declaration submitted against them
* if a participant is withdrawn later in their course, we'll pay providers for any declarations submitted where the `declaration_date` is before the withdrawal date
* the amount we'll pay depends on which milestones have been reached with declarations submitted before withdrawal

For more detailed information, see the ['Withdraw a participant' endpoint documentation](/api/docs/v3#/NPQ%20Participants/put_api_v3_participants_npq__id__withdraw).

### Example request body

```json
{
  "data": {
    "type": "participant-withdraw",
    "attributes": {
      "course_identifier": "npq-senior-leadership",
      "reason": "insufficient-capacity-to-undertake-programme"
    }
  }
}
```

## Notify that a participant is changing training schedule

```
PUT /api/v3/participants/npq/{id}/change-schedule
```

The API will automatically assign schedules to participants depending on when course applications are accepted by providers. Providers must notify DfE of any **schedule change**.

Successful requests will return a response body including updates to the `schedule_identifier` attribute.

### What if the declaration date and new schedule's milestone dates do not align? 

The API will reject a schedule change if any submitted, eligible, payable or paid declarations have a `declaration_date` which does not align with the new schedule’s milestone dates.

For example, a participant is in the 2023 cohort on an `npq-specialist-autumn` schedule. Their provider has submitted a started declaration dated 1 October 2023. The provider tries to change the schedule to `npq-specialist-spring`. The API will reject the change because a spring schedule does not start until January, which is after the declaration date. The API returns an error message with instructions to void existing declarations first.

For more detailed information, see the ['Notify that a participant is changing training schedule' endpoint documentation](/api/docs/v3#/NPQ%20Participants/put_api_v3_participants_npq__id__change_schedule).

### Example request body

```json
{
  "data": {
    "type": "participant-change-schedule",
    "attributes": {
      "schedule_identifier": "npq-ehco-march",
      "course_identifier": "npq-early-headship-coaching-offer",
      "cohort": "2023"
    }
  }
}
```

## Retrieve multiple NPQ outcomes for all participants

```
GET /api/v3/participants/npq/outcomes
```

Participants can either pass or fail assessment at the end of their NPQ course. These outcomes are submitted by providers within `completed` declaration submissions.

<div class="govuk-inset-text">
Outcomes are sent to the Database of Qualified Teachers (DQT). They issue certificates to participants who've passed.
</div>

Successful requests will return a response body including an outcome `state` value to signify:

* outcomes submitted (`passed` or `failed`)
* if `completed` declarations have been voided and the outcome retracted (`voided`)

For more detailed information, see the ['Retrieve multiple NPQ outcomes for all participants' endpoint documentation](/api/docs/v3#/NPQ%20Participant%20Outcomes/get_api_v3_participants_npq_outcomes).

### Example response body

```json
{
  "data": [
    {
      "id": "d0b4a32e-a272-489e-b30a-cb17131457fc",
      "type": "participant-outcome",
      "attributes": {
        "state": "passed",
        "completion_date": "2021-05-31T00:00:00+00:00",
        "course_identifier": "npq-senior-leadership",
        "participant_id": "7a8fef46-3c43-42c0-b3d5-1ba5904ba562",
        "created_at": "2021-05-31T02:21:32.000Z",
        "updated_at": "2021-05-31T02:22:32.000Z"
      }
    }
  ]
}
```

## Retrieve multiple outcomes for a single participant

```
GET /api/v3/participants/npq/{id}/outcomes
```

A participant can either pass or fail assessment at the end of their NPQ course. Their outcome will be submitted by providers within `completed` declaration submissions.

<div class="govuk-inset-text">
Outcomes are sent to the Database of Qualified Teachers (DQT). They issue certificates to participants who've passed.
</div>

Successful requests will return a response body including an outcome `state`value to signify:

* the outcome submitted (`passed` or `failed`)
* if the `completed` declaration has been `voided` and the outcome retracted (`voided`)

For more detailed information, see the ['Retrieve multiple NPQ outcomes for a single participant' endpoint documentation](/api/docs/v3#/NPQ%20Participant%20Outcomes/get_api_v3_participants_npq__id__outcomes).

### Example response body

```json
{
  "data": [
    {
      "id": "d0b4a32e-a272-489e-b30a-cb17131457fc",
      "type": "participant-outcome",
      "attributes": {
        "state": "passed",
        "completion_date": "2021-05-31T00:00:00+00:00",
        "course_identifier": "npq-senior-leadership",
        "participant_id": "7a8fef46-3c43-42c0-b3d5-1ba5904ba562",
        "created_at": "2021-05-31T02:21:32.000Z",
        "updated_at": "2021-05-31T02:22:32.000Z"
      }
    }
  ]
}
```

## Submit an NPQ outcome for single participant

```
POST /api/v3/participants/npq/{id}/outcomes
```

Outcomes may need to be updated if previously submitted data was inaccurate. For example, a provider should update a participant’s outcome if:

* the reported outcome was incorrect
* the reported date the participant received their outcome was incorrect
* a participant has retaken their NPQ assessment and their outcome has changed

Request bodies must include a new value for the outcome `state` and `completion_date`.

Successful requests will return a response body with updates included.

For more detailed information, see the ['Submit an NPQ outcome for a single participant' endpoint documentation](/api/docs/v3#/NPQ%20Participant%20Outcomes/post_api_v3_participants_npq__id__outcomes).

### Example request body

```json
{
  "data": {
    "type": "npq-outcome-confirmation",
    "attributes": {
      "course_identifier": "npq-senior-leadership",
      "state": "passed",
      "completion_date": "2021-05-31T00:00:00+00:00"
    }
  }
}
```
