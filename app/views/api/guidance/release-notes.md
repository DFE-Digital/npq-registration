# Release notes

If you have any questions or comments about these notes, contact DfE via Slack or email.

## 1 July 2024
Registration has opened for the 2024/25 intake of NPQ participant applications, so we’ve added the following to the production environment:

* the 2024/25 NPQ data and schedules
* functionality which enables providers to set whether NPQ applicants are going to have their training funded by DfE
* the new special education needs coordinator (SENCO) NPQ

See the 14 June release note for more details about the funded training functionality and SENCO NPQ.

## 14 June 2024

We’ve added the new special educational needs coordinator (SENCO) NPQ to the test (sandbox) environment for the 2024 cohort.

The new course’s identifier is ```npq-senco```.

Providers can access this within the sandbox environment for testing. Functionality will be the same as the other existing NPQ courses.

We’ll notify providers when this new NPQ is available in the production environment.

We’re trialing new functionality in the API test (sandbox) environment which will enable providers to set whether NPQ applicants are going to have their training funded by DfE.

This is because from the 2024/25 academic year onwards there’ll be a set maximum number of places each provider can offer per NPQ that DfE will pay for.

Providers using all versions of the API can set the new ```funded_place``` field in the ‘Accept an application’ request body to ```true``` or ```false```. They will also see the ```funded_place``` field in the following endpoint response bodies:

* ‘View all applications’

* ‘View a specific application’

* ‘View all participant data’

* ‘View a single participant’s data’

Providers who need to update a participant’s funding information after an application has been accepted can do so via the ‘Change funded place’ endpoint.

