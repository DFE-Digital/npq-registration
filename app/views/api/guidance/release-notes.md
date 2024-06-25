# Release notes

If you have any questions or comments about these notes, please contact DfE via Slack or email.

## 13 August 2024 

We’ve released a minimum viable product (MVP) version of the standalone National Professional Qualifications (NPQ) API for providers to test ahead of its full launch at the end of November 2024. We plan to run this test phase until the end of October and will support providers via regular dedicated meetings to ensure testing is going smoothly. 

### Get started in the test environments 

To help providers integrate smoothly with the MVP, we've launched ‘separation’ test environments populated with relevant seed data and featuring all the NPQ endpoints. These will eventually replace the existing sandboxes.  

To make requests in the new test environments, providers must use the bearer tokens that we’ve sent them via Galaxkey. The base URL is:  

- [https://npq-registration-separation-web.teacherservices.cloud](https://npq-registration-separation-web.teacherservices.cloud)

Providers can add the required API version and endpoint depending on what they want to test. For example, /api/v3/npq-applications if they want to retrieve multiple applications.  

To see the standalone API endpoints documentation, go to:  

- [version 1 endpoints documentation](https://npq-registration-separation-web.teacherservices.cloud/api/docs/v1)
- [version 2 endpoints documentation](https://npq-registration-separation-web.teacherservices.cloud/api/docs/v2)
- [version 3 endpoints documentation](https://npq-registration-separation-web.teacherservices.cloud/api/docs/v3)

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
