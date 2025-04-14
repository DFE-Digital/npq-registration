# Release notes

If you have any questions or comments about these notes, please contact DfE via Slack or email.

## 14 April 2025

[#new-feature #sandbox-release]

We’ve made updates in the sandbox environment to improve how lead providers interact with the service.

We’ve added delivery partner api endpoints so that you can fetch assigned delivery partners. You can filter by cohort to help quickly find specific results.

The `Declarations GET` endpoint has been extended to include `delivery_partner_id` and `secondary_delivery_partner_id` attributes.

We have also extended the `Declarations POST` endpoint to enable submissions that include `delivery_partner_id` and `secondary_delivery_partner_id`(where applicable).

Starting from 28 April 2025, the `delivery_partner_id` will be required for cohort 2024 declarations and later in the sandbox environment, excluding overseas applicants.



## 27 November 2024

We've launched the live standalone National Professional Qualifications (NPQs) API following a 3-month test phase.

We’ve migrated NPQ data from the combined ECF/NPQs API to the new environment, so providers must now make all NPQ-related calls from this API.

To make requests in the new live environment, providers must use the bearer tokens that we’ve sent them via Galaxkey.

The base URL is:

- [https://register-national-professional-qualifications.education.gov.uk/](https://register-national-professional-qualifications.education.gov.uk/)

Providers can add the required API version and endpoint depending on what they want to do. For example, they’d add `/api/v3/npq-applications` to the base URL if they want to retrieve multiple applications.

We’ve also created documentation for the new live environment endpoints:

- [NPQ API v1 documentation](https://register-national-professional-qualifications.education.gov.uk/api/docs/v1)
- [NPQ API v2 documentation](https://register-national-professional-qualifications.education.gov.uk/api/docs/v2)
- [NPQ API v3 documentation](https://register-national-professional-qualifications.education.gov.uk/api/docs/v3)

To ensure everything runs smoothly, we recommend providers take the following post-separation actions:

- check their integration supports NPQ calls independently
- make sure all data flows and integrations continue to work as expected
- test internal processes to verify that data from the NPQ environment is being handled appropriately
- conduct full data syncs within their allocated window so that data is up to date and accurate

Providers can contact us via their dedicated DfE Slack channel if they’ve got any suggestions or concerns.

## 13 August 2024

We’ve released a minimum viable product (MVP) version of the standalone National Professional Qualifications (NPQ) API for providers to test ahead of its full launch at the end of November 2024. 

We plan to run this test phase until the end of October and will support providers via regular dedicated meetings to ensure testing is going smoothly.

### Get started in the test environments

To help providers integrate smoothly with the MVP, we've launched ‘separation’ test environments populated with relevant seed data and featuring all the NPQ endpoints. These will eventually replace the existing sandboxes.

To make requests in the new test environments, providers must use the bearer tokens that we’ve sent them via Galaxkey. The base URL is:

- [https://npq-registration-separation-web.teacherservices.cloud](https://npq-registration-separation-web.teacherservices.cloud)

Providers can add the required API version and endpoint depending on what they want to test. For example, /api/v3/npq-applications if they want to retrieve multiple applications.

To see the standalone API endpoints documentation, go to:

- [version 1 endpoints documentation](/api/docs/v1)
- [version 2 endpoints documentation](/api/docs/v2)
- [version 3 endpoints documentation](/api/docs/v3)

We've also created ECF-only test environments so providers who offer both ECF and NPQ training can undertake regression testing. The base URL is:

- [https://sp.manage-training-for-early-career-teachers.education.gov.uk](https://sp.manage-training-for-early-career-teachers.education.gov.uk)

What seed data will be generated for the NPQ API

We’ll be generating seed data which cover scenarios where users have:

- one application
- multiple applications
- accepted applications
- rejected applications

Providers can also create ‘dummy’ applications in the separation environment. This enables them to:

- generate individualised seed data
- test specific scenarios that suit their needs
- familiarise themselves with how participants register
- check internal processes

### Provider tech support

Contact us via the engagement and policy leads if you want to discuss your integration and technical plans in more detail.

Our team are happy to host technical workshops with providers to ensure this integration runs smoothly.
