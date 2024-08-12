# View, accept or reject applications

<div class="govuk-inset-text">
  Providers must accept or reject applications before participants start a course and inform applicants of the outcome regardless of whether the application has been accepted or rejected.
</div>

Providers can **view application data** to find out if NPQ applicants:

* have a valid email address
* have a valid teacher reference number (TRN)
* are eligible for funding
* have a funded place

Providers can then accept or reject NPQ course applications.

While people can make multiple applications for the same course, with one or multiple providers, only one provider can accept an application from a participant for an NPQ course.

To prevent a participant being enrolled onto the same course with more than one provider the API will:

* **automatically update the** `status` to `rejected` **for all other applications**. If someone has made multiple applications with different providers (within a given cohort) and a provider accepts one, the API will update the `status` of all other applications with other providers to `rejected`
* **return an error message for new applications**. If a participant has had an application accepted by a provider, but then makes a new application for the same course with a new provider, the API will return an error message if the new provider tries to accept the new application

<div class="govuk-inset-text">
While participants can enter different email addresses when applying for training courses, providers will only see the email address associated with a given course application or registration. DfE will share the relevant email address with the relevant course provider.
</div>


## Retrieve multiple applications

```
GET /api/v3/npq-applications
```

Providers can filter results to see more specific or up to date data by adding `cohort`, `participant_id` and `updated_since` filters to the parameter. 

For example: `GET /api/v3/npq-applications?filter[cohort]=2021&filter[participant_id]=7e5bcdbf-c818-4961-8da5-439cab1984e0&filter[updated_since]=2020-11-13T11:21:55Z`

See the <a href="https://npq-registration-separation-web.teacherservices.cloud/api/docs/v3#/NPQ%20Applications/get_api_v3_npq_applications">'Retrieve multiple applications' endpoint documentation</a> for more information.

### Example response body

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
        "funded_place": null
      }
    }
  ]
}
```

## Retrieve a single application

```
GET /api/v3/npq-applications/{id}
```

See the <a href="https://npq-registration-separation-web.teacherservices.cloud/api/docs/v3#/NPQ%20Applications/get_api_v3_npq_applications__id_">'Retrieve a single application' endpoint documentation</a> for more information.

### Example response body

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
      "funded_place": null
    }
  }
}
```

## Accept an application

```
POST /api/v3/npq-applications/{id}/accept
```

Providers should accept applications for those they want to enrol onto a course. Providers must inform applicants of the outcome of their successful NPQ application.

Reasons to accept applications include (but are not limited to) the participant:

* having funding confirmed
* being suitable for their chosen NPQ course
* having relevant support from their school

The request parameter must include the `id` of the corresponding NPQ application.

An optional request body allows lead providers to add a participant’s schedule when accepting NPQ applications.

### Example request body

```
{
  "data": {
    "type": "npq-application-accept",
    "attributes": {
      "schedule_identifier": "npq-leadership-spring"
      "funded_place": null
    }
  }
}
```

Successful requests will return a response body including updates to the status attribute.
<div class="govuk-inset-text">
The API will prevent more than one provider accepting applications for the same course by automatically updating the application status or returning an error message.
</div>

See the <a href="https://npq-registration-separation-web.teacherservices.cloud/api/docs/v3#/NPQ%20Applications/post_api_v3_npq_applications__id__accept">'Accept an application' endpoint documentation</a> for more information.

### Example response body

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
      "funded_place": true,
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

## Reject an application

```
POST /api/v3/npq-applications/{id}/reject
```

Providers should **reject applications** for those they do not want to enrol onto a course. 

Providers **must inform applicants** of the outcome of their unsuccessful NPQ application.

Reasons to reject applications include (but are not limited to) the participant:

* having been unsuccessful in their application process
* not having secured funding
* wanting to use another provider
* wanting to take on another course
* no longer wanting to take the course

The request parameter must include the `id` of the corresponding NPQ application.

Successful requests will return a response body including updates to the `status` attribute.

See the <a href="https://npq-registration-separation-web.teacherservices.cloud/api/docs/v3#/NPQ%20Applications/post_api_v3_npq_applications__id__reject">'Reject an application' endpoint documentation</a> for more information.

### Example request body

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
      "funded_place": null
    }
  }
}
```

## Change funded place value of an application

```
PUT/api/v3/npq-applications/{id}/change-funded-place 
```

Providers can update a participant’s funding information after an application has been accepted.

It’s not possible to change this information if the application has not been accepted.

See the <a href="https://npq-registration-separation-web.teacherservices.cloud/api/docs/v3#/NPQ%20Applications/put_api_v3_npq_applications__id__change_funded_place">'Change funded place value of an application' endpoint documentation</a> for more information.

### Example request body:

```
{ 
  "data": { 
    "type": "npq-application-change-funded-place", 
    "attributes": { 
      "funded_place": true 
    } 
  } 
}
```

Successful requests will return a response body including updates to the ```funded_place``` attribute.

### Example response body:

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
      "funded_place": true, 
      "funding_choice": "trust", 
      "course_identifier": "npq-leading-teaching", 
      "status": "pending", 
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

## Update an application due to a change in circumstance

There are several reasons why there might be a change in circumstance for an NPQ application, including where a participant:

* made a mistake during their application
* selected the wrong course during their application
* wants to take another course instead
* wants to fund their NPQ differently

Where there has been a change in circumstance, providers should:

* reject the application if the application `status` is `pending`
* contact DfE if the application `status` is `accepted` 

For example, if a participant registers for an NPQ course but then decides to change to another course, the provider should:

1. Reject that participant’s application.
2. Ask the participant to re-register on the NPQ registration service, entering the correct course details.
3. Accept the new application once it is available via the API.