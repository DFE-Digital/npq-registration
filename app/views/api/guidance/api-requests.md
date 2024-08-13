# API requests

## View, accept or reject NPQ applications

Providers can **view application data** to find out whether NPQ applicants:

* have a valid email address
* have a valid teacher reference number (TRN)
* are eligible for funding

Providers can then accept or reject applications to NPQ courses.

While people can make multiple applications for the same course, with one or multiple providers, only one provider can accept an application from a participant for an NPQ course.

To prevent a participant being enrolled onto the same course with more than one provider the API will:

* **automatically update the** `status` to `rejected` **for all other applications**. If someone has made multiple applications with different providers (within a given cohort) and a provider accepts one, the API will update the `status` of all other applications with other providers to `rejected`
* **return an error message for new applications**. If a participant has had an application accepted by a provider, but then makes a new application for the same course with a new provider, the API will return an error message if the new provider tries to accept the new application

[WARNING TEXT] Providers must accept or reject applications before participants start a course and inform applicants of the outcome regardless of whether the application has been accepted or rejected.

[INSET TEXT] While participants can enter different email addresses when applying for training courses, providers will only see the email address associated with a given course application or registration. DfE will share the relevant email address with the relevant course provider.

### View all applications

```
GET /api/v3/npq-applications
```

[INSET TEXT] Providers can filter results to see more specific or up to date data by adding `cohort`, `participant_id` and `updated_since` filters to the parameter. For example: `GET /api/v3/npq-applications?filter[cohort]=2021&filter[participant_id]=7e5bcdbf-c818-4961-8da5-439cab1984e0&filter[updated_since]=2020-11-13T11:21:55Z`

See the ```view multiple NPQ applications``` endpoint documentation [ADD LINK] for more information.

#### Example ```response``` body

```
{
  "data": [
    {
      "id": "db3a7848-7308-4879-942a-c4a70ced400a",
      "type": "npq_application",
      "attributes": {
        "course_identifier": "npq-leading-teaching-development",
        "email": "isabelle.macdonald2@some-school.example.com",
        "email_validated": true,
        "employer_name": null,
        "employment_role": null,
        "full_name": "Isabelle MacDonald",
        "funding_choice": null,
        "headteacher_status": null,
        "ineligible_for_funding_reason": null,
        "participant_id": "53847955-7cfg-41eb-a322-96c50adc742b",
        "private_childcare_provider_urn": null,
        "teacher_reference_number": "0743795",
        "teacher_reference_number_validated": true,
        "school_urn": "123456",
        "school_ukprn": "12345678",
        "status": "pending",
        "works_in_school": true,
        "created_at": "2022-07-06T10:47:24Z",
        "updated_at": "2022-11-24T17:09:37Z",
        "cohort": "2022",
        "eligible_for_funding": true,
         "targeted_delivery_funding_eligibility": false,
        "teacher_catchment": true,
        "teacher_catchment_iso_country_code": "GBR",
        "teacher_catchment_country": "United Kingdom of Great Britain and Northern Ireland",
        "itt_provider": null,
        "schedule_identifier": "npq-leadership-spring"
      }
    }
  ]
}
```

### View a specific application

```GET /api/v3/npq-applications/{id}```

See the ```view a specific NPQ application``` endpoint documentation [ADD LINK] for more information.

#### Example ```response``` body

```
{
  “data”: {
    “id”: “db3a7848-7308-4879-942a-c4a70ced400a”,
    “type”: “npq_application”,
    “attributes”: {
      “participant_id”: “7a8fef46-3c43-42c0-b3d5-1ba5904ba562",
      “full_name”: “Isabelle MacDonald”,
      “email”: “isabelle.macdonald2@some-school.example.com”,
      “email_validated”: true,
      “teacher_reference_number”: “1234567”,
      “teacher_reference_number_validated”: true,
      “works_in_school”: true,
      “employer_name”: “Some Company Ltd”,
      “employment_role”: “Director”,
      “school_urn”: “106286”,
      “private_childcare_provider_urn”: “EY944860”,
      “school_ukprn”: “10079319”,
      “headteacher_status”: “no”,
      “eligible_for_funding”: true,
      “funding_choice”: “trust”,
      “course_identifier”: “npq-leading-teaching”,
      “status”: “pending”,
      “created_at”: “2021-05-31T02:21:32.000Z”,
      “updated_at”: “2021-05-31T02:22:32.000Z”,
      “ineligible_for_funding_reason”: “establishment-ineligible”,
      “cohort”: “2022",
      “targeted_delivery_funding_eligibility”: true,
      “teacher_catchment”: true,
      “teacher_catchment_country”: “France”,
      “teacher_catchment_iso_country_code”: “FRA”,
      “itt_provider”: “University of Southampton”,
      "schedule_identifier": "npq-leadership-spring"
    }
  }
}
```

### Accept an application

```POST /api/v3/npq-applications/{id}/accept```

Providers should accept applications for those they want to enrol onto a course. Providers must inform applicants of the outcome of their successful NPQ application.

Reasons to accept applications include (but are not limited to) the participant:

* having funding confirmed
* being suitable for their chosen NPQ course
* having relevant support from their school

The request parameter must include the `id` of the corresponding NPQ application.

An optional request body allows lead providers to add a participant’s schedule when accepting NPQ applications.

#### Example request body

```
{
  "data": {
    "type": "npq-application-accept",
    "attributes": {
      "schedule_identifier": "npq-leadership-spring"
    }
  }
}
```

Successful requests will return a response body including updates to the status attribute.

[INSET TEXT] The API will prevent more than one provider accepting applications for the same course by automatically updating the application status or returning an error message.

See the ```accept an NPQ application``` endpoint documentation [ADD LINK] for more information.

#### Example ```response``` body

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "npq_application",
    "attributes": {
      "participant_id": "7a8fef46-3c43-42c0-b3d5-1ba5904ba562",
      "full_name": "Isabelle MacDonald",
      "email": "isabelle.macdonald2@some-school.example.com",
      "email_validated": true,
      "teacher_reference_number": "1234567",
      "teacher_reference_number_validated": true,
      "works_in_school": true,
      "employer_name": "Some Company Ltd",
      "employment_role": "Director",
      "school_urn": "106286",
      "private_childcare_provider_urn": "EY944860",
      "school_ukprn": "10079319",
      "headteacher_status": "no",
      "eligible_for_funding": true,
      "funding_choice": "trust",
      "course_identifier": "npq-leading-teaching",
      "status": "accepted",
      "created_at": "2021-05-31T02:21:32.000Z",
      "updated_at": "2021-05-31T02:22:32.000Z",
      "ineligible_for_funding_reason": "establishment-ineligible",
      "cohort": "2022",
      "targeted_delivery_funding_eligibility": true,
      "teacher_catchment": true,
      "teacher_catchment_country": "France",
      "teacher_catchment_iso_country_code": "FRA",
      "lead_mentor": true,
      "itt_provider": "University of Southampton",
      "schedule_identifier": "npq-leadership-spring"
    }
  }
}
```

### Reject an application

Providers should **reject applications** for those they do not want to enrol onto a course. Providers must inform applicants of the outcome of their unsuccessful NPQ application.

Reasons to reject applications include (but are not limited to) the participant:

* having been unsuccessful in their application process
* not having secured funding
* wanting to use another provider
* wanting to take on another course
* no longer wanting to take the course

```
POST /api/v3/npq-applications/{id}/reject
```

The request parameter must include the `id` of the corresponding NPQ application.

An example response body is listed below. Successful requests will return a response body including updates to the `status` attribute.

See the ```accept an NPQ application``` endpoint documentation [ADD LINK] for more information.

#### Example ```request``` body

```
{
  "data": {
    "id": "db3a7848-7308-4879-942a-c4a70ced400a",
    "type": "npq_application",
    "attributes": {
      "participant_id": "7a8fef46-3c43-42c0-b3d5-1ba5904ba562",
      "full_name": "Isabelle MacDonald",
      "email": "isabelle.macdonald2@some-school.example.com",
      "email_validated": true,
      "teacher_reference_number": "1234567",
      "teacher_reference_number_validated": true,
      "works_in_school": true,
      "employer_name": "Some Company Ltd",
      "employment_role": "Director",
      "school_urn": "106286",
      "private_childcare_provider_urn": "EY944860",
      "school_ukprn": "10079319",
      "headteacher_status": "no",
      "eligible_for_funding": true,
      "funding_choice": "trust",
      "course_identifier": "npq-leading-teaching",
      "status": "rejected",
      "created_at": "2021-05-31T02:21:32.000Z",
      "updated_at": "2021-05-31T02:22:32.000Z",
      "ineligible_for_funding_reason": "establishment-ineligible",
      "cohort": "2022",
      "targeted_delivery_funding_eligibility": true,
      "teacher_catchment": true,
      "teacher_catchment_country": "France",
      "teacher_catchment_iso_country_code": "FRA",
      "lead_mentor": true,
      "itt_provider": "University of Southampton",
      "schedule_identifier": "npq-leadership-spring"
    }
  }
}
```

### Update an application due to a change in circumstance

There are several reasons why there might be a change in circumstance for an NPQ application, including where a participant:

* made a mistake during their application
* selected the incorrect course during their application
* wants to take another course instead
* wants to fund their NPQ differently

Where there has been a change in circumstance, providers should:

* reject the application if the application `status` is `pending`
* contact DfE if the application `status` is `accepted`. 

For example, if a participant registers for an NPQ course but then decides to change to another course, the provider should:

1. Reject that participant’s application.
2. Ask the participant to re-register on the NPQ registration service, entering the correct course details.
3. Accept the new application once it is available via the API.

## View and update participant data

Once a provider has accepted an application, they can **view and update data** to notify DfE that a participant has:

* deferred their course [ADD LINK]
* resumed their course [ADD LINK]
* withdrawn from their course [ADD LINK]
* changed their course schedule [ADD LINK]
* an updated course outcome [ADD LINK]

### View all participant data

```
GET /api/v3/participants/npq
```

[INSET TEXT] Providers can **filter results** by adding `updated_since` filters to the parameter. For example: `GET /api/v{n}/participants/ecf?filter[updated_since]=2020-11-13T11:21:55Z`

#### Check for participant ID changes

Providers can check if an NPQ participant’s ID has changed using the `participant_id_changes` nested structure in the NPQEnrolment [ADD LINK], which contains a `from_participant_id` and a `to_participant_id` string fields, as well a `changed_at` date value.

#### Duplicate IDs 

We've previously advised [ADD LINK] of the possibility that participants may be registered as duplicates with multiple participant IDs. Where we identify duplicates, we'll fix the error by ‘retiring’ one of the participant IDs, then associating all records and data under the remaining ID.

For more detailed information, see the ```view multiple NPQ participants``` endpoint documentation [ADD LINK].

#### Example ```response``` body

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

### View a single participant’s data

```
GET /api/v3/participants/npq/{id}
```

#### Check for participant ID changes

Providers can check if an NPQ participant’s ID has changed using the `participant_id_changes` nested structure in the NPQEnrolment [AD LINK], which contains a `from_participant_id` and a `to_participant_id` string fields, as well a `changed_at` date value.

#### Duplicate IDs 

We've previously advised [ADD LINK] of the possibility that participants may be registered as duplicates with multiple participant IDs. 

Where we identify duplicates, we'll fix the error by ‘retiring’ one of the participant IDs, then associating all records and data under the remaining ID. 

To date, when this has occurred, we’ve informed providers of changes via CSVs

For more detailed information, see the ```view multiple NPQ participants``` endpoint documentation [ADD LINK].

#### Example ```response``` body

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

### Notify DfE a participant has deferred their training

```
PUT /api/v{n}/participants/npq/{id}/defer
```

A participant can choose to **defer** their course at any time if they plan to resume training at a later date. Providers must notify DfE of this via the API.

Successful requests will return a response body including updates to the ```training_status``` attribute.

For more detailed information, see the ```notify DfE that an NPQ participant is taking a break from their course``` endpoint documentation [ADD LINK].

#### Example ```request``` body

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

### Notify DfE a participant has resumed training

```
PUT /api/v3/participants/npq/{id}/resume
```

A participant can **resume** their course at any time if they've previously deferred. Providers must notify DfE of this via the API.

Successful requests will return a response body including updates to the ```training_status``` attribute.

For more detailed information, see the ```notify DfE that an NPQ participant has resumed training``` endpoint documentation [ADD LINK].

#### Example ```request``` body

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

### Notify DfE a participant has withdrawn from training

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

#### Example ```request``` body

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

### Notify DfE a participant has changed their training schedule

```
PUT /api/v3/participants/npq/{id}/change-schedule
```

The API will automatically assign schedules to participants depending on when course applications are accepted by providers. Providers must notify DfE of any **schedule change**.

Successful requests will return a response body including updates to the ```schedule_identifier``` attribute.

#### What if the declaration date and new schedule's milestone dates do not align? 

The API will reject a schedule change if any submitted, eligible, payable or paid declarations have a ```declaration_date``` which does not align with the new schedule’s milestone dates. 

For example, a participant is in the 2023 cohort on an ```npq-specialist-autumn``` schedule. Their provider has submitted a started declaration dated 1 October 2023. The provider tries to change the schedule to ```npq-specialist-spring```. The API will reject the change because a spring schedule does not start until January, which is after the declaration date. The API returns an error message with instructions to void existing declarations first.

For more detailed information, see the ```notify that an NPQ participant has changed their training schedule``` endpoint documentation [ADD LINK].

#### Example ```request``` body

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

### View all participant outcomes

```
GET /api/v3/participants/npq/outcomes
```

Participants can either pass or fail assessment at the end of their NPQ course. These outcomes are submitted by providers within ```completed``` declaration submissions.

[INSET TEXT] Outcomes are sent to the Database of Qualified Teachers (DQT). They issue certificates to participants who've passed.

Successful requests will return a response body including an outcome ```state``` value to signify:

* outcomes submitted (```passed``` or ```failed```)
* if ```completed``` declarations have been voided and the outcome retracted (```voided```)

For more detailed information, see the ```view NPQ outcomes``` endpoint documentation [ADD LINK].

#### Example ```response``` body

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

### View a specific participant’s outcome

```
GET /api/v3/participants/npq/{participant_id}/outcomes
```

A participant can either pass or fail assessment at the end of their NPQ course. Their outcome will be submitted by providers within ```completed``` declaration submissions.

[INSET TEXT ] Outcomes are sent to the Database of Qualified Teachers (DQT). They issue certificates to participants who've passed.

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

### Update a participant’s outcomes

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

### Example ```request``` body

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

## Submit, view and void declarations

Providers must submit declarations in line with NPQ contractual schedules and milestone dates [ADD LINK].

These declarations will trigger payment from DfE to providers.

When providers submit declarations, API response bodies will include data about which financial statement the given declaration applies to. Providers can then view financial statement payment dates [ADD LINK] to check when the invoicing period, and expected payment date, will be for the given declaration.

### Test the ability to submit declarations in sandbox ahead of time

```X-With-Server-Date``` is a custom JSON header supported in the sandbox environment. It lets providers test their integrations and ensure they are able to submit declarations for future milestone dates.

The ```X-With-Server-Date``` header lets providers simulate future dates, and therefore allows providers to test declaration submissions for future milestone dates.

[INSET TEXT] It is only valid in the sandbox environment. Attempts to submit future declarations in the production environment (or without this header in sandbox) will be rejected as part of milestone validation.
To test declaration submission functionality, include:

* the header ```X-With-Server-Date``` as part of declaration submission request
* the value of your chosen date in the ISO 8601 format with time and time zone (the RFC 3339 format). For example:
```X-With-Server-Date: 2022-01-10T10:42:00Z```

### Notify DfE a participant has started training

```
POST /api/v3/participant-declarations
```

Notify DfE a participant has started an NPQ course by submitting a ```started``` declaration in line with milestone 1 dates [ADD LINK].

Request bodies must include the necessary data attributes, including the ```declaration_type``` attribute with a started value.

Successful requests will return a response body with declaration data.

Any attempts to submit duplicate declarations will return an error message.

[INSET TEXT] Providers should store the returned NPQ participant declaration ID for management tasks.

For more detailed information, see the ```notify DfE that an NPQ participant has started training``` endpoint documentation [ADD LINK].

#### Example ```request``` body

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

#### Example ```response``` body

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

### Notify DfE a participant has been retained in training

```
POST /api/v{n}/participant-declarations
```

Notify DfE a participant has reached a given retention point in their course by submitting a ```retained``` declaration in line with milestone dates [ADD LINK].

Request bodies must include the necessary data attributes, including the appropriate ```declaration_type``` attribute value, for example ```retained-1```.

An example response body is listed below. Successful requests will return a response body with declaration data.

Any attempts to submit duplicate declarations will return an error message.

[INSET TEXT] Providers should store the returned NPQ participant declaration ID for management tasks.
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

### Notify DfE a participant has completed training

```
POST /api/v{n}/participant-declarations
```

Notify DfE a participant has completed their course by submitting a ```completed``` declaration in line with milestone dates [ADD LINK].

You can do this for all NPQs and the Early headship coaching offer.

Request bodies must include the necessary data attributes, including the ```declaration_type``` attribute with a ```completed``` value, and the ```has_passed``` attribute with a ```true``` or ```false value```.

Successful requests will return a response body with declaration data.

[WARNING TEXT] Any attempts to submit duplicate declarations will return an error message.

[INSET TEXT] Providers should store the returned NPQ participant declaration ID for future management tasks.

For more detailed information, see the ```notify DfE that an NPQ participant has completed training``` endpoint documentation [ADD LINK].

#### Example ```request``` body 

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

#### Example ```response``` body

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

### View all previously submitted declarations

```
GET /api/v3/participant-declarations
```

View all declarations which have been submitted to date. Check declaration submissions, identify if any are missing, and void or clawback those which have been submitted in error.

[INSET TEXT] Providers can also filter results by adding filters to the parameter. For example: ```GET /api/v3/participant-declarations?filter[participant_id]=ab3a7848-1208-7679-942a-b4a70eed400a``` or ```GET /api/v3/participant-declarations?filter[cohort]=2022&filter[updated_since]=2020-11-13T11:21:55Z```

For more detailed information see the specifications for this view all declarations endpoint [ADD LINK].

#### Example ```response``` body:

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

### View a specific previously submitted declaration

```
GET /api/v3/participant-declarations/{id}
```

View a specific declaration which has been previously submitted. Check declaration details and void or clawback those which have been submitted in error.

For more detailed information, see the ```view specific declarations``` endpoint documentation [ADD LINK].

#### Example ```response``` body:

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

### Void or clawback a declaration

```
PUT /api/v3/participant-declarations/{id}/void
```

Void specific declarations which have been submitted in error.

Successful requests will return a response body including updates to the declaration ```state```, which will become:

* ```voided``` if it had been ```submitted```, ```ineligible```, ```eligible```, or ```payable```
* ```awaiting_clawback``` if it had been paid

View more information on declaration states [HYPERLINK]

[INSET TEXT] If a provider voids a ```completed``` declaration, the outcome (indicating whether they have passed or failed) will be retracted. The ```has_passed``` value will revert to ```null```.

For more detailed information, see the ```void declarations``` endpoint documentation [ADD LINK].

#### Example ```response``` body

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

## View payments information 

[INSET TEXT] The following endpoints are only available for systems integrated with API v3 onwards. They will not return data for API v1 or v2.

Providers can view up to date payment cut-off dates, upcoming payment dates, and check to see whether output payments have been made by DfE.

### View all statement payment dates

```
GET /api/v3/statements
```

For more detailed information, see the ```view all statements``` endpoint documentation [ADD LINK].

#### Example ```response``` body

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

### View specific statement payment dates

```
GET /api/v3/statements/{id}
```

Providers can find statement IDs within previously submitted declaration response bodies.

For more detailed information see, the ```view a specific statement``` endpoint documentation [ADD LINK].

#### Example ```response``` body

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