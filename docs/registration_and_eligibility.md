[< Back to Navigation](../README.md)

# What is NPQ?

NPQ Registration is a Rails application that allows teachers to apply for National Professional Qualifications (NPQs) in England.

1. [The Registration Wizard](#the-registration-wizard)
1. [Courses](#courses)
1. [Lead Providers](#lead-providers)
1. [Funding Eligibility](#funding-eligibility)
1. [Preparation for Re-opening](#preparation-for-re-opening)
1. [Re-opening](#re-opening)

# How does it work?

## The Registration Wizard

The core flow of NPQ is the Registration Wizard. This is a series of questions that the user must answer in order to complete their application.

This core flow is a loop through the registration_wizard#show and registration_wizard#update actions. The user visits a page, the corresponding Form object is loaded with the user's store from their session, and the form is rendered. This occurs within registration_wizard#show.

When the user submits the form, the corresponding Form object is loaded with the user's store from their session and the form is validated. If the form is valid, the user's store is updated with the form's attributes and the user is redirected to the next step in the wizard. If the form is invalid, the user is redirected back to the form with the errors displayed.

### The Forms

Form objects are found within [app/forms](app/forms). Each Form Object is responsible for validating the user's input and updating the user's store with the form's attributes.

It defines the question name, validations, and the next_step and previous_step.

### The Store

The store is a session based store of the user's current application state. It is a hash that is stored in the user's session and is updated as the user progresses through the wizard. It is accessed by calling `wizard.store` on or within a form. The Query Store (detailed below) provides a way to access the store in a stuctured way.

### RegistrationQueryStore

The RegistrationQueryStore service is a wrapper around the store hash, providing helper methods to access store information.

### Courses

The Course model represents the different NPQs that are available to apply for. Each course has an `identifier` which is used to identify the course in the API.

### Lead Providers

The LeadProvider model represents the different Lead Providers that are able to provide training on the various NPQ courses. Each course has a different set of LeadProviders that can be selected. This is determined by calling `LeadProvider.for(course:)` when the user is presented their list of Lead Providers to choose from.

## Funding Eligibility

Funding Eligibility occurs once the user has finished questions related to their application, selected their NPQ and their provider. This information is then fed into `FundingEligibility`. This service then determines the user's eligibility for government funding and will provide a boolean funded status along with a `funding_eligiblity_status_code` which encodes the reason why a user may not have been funded.

## Preparation for Re-opening

Several tasks need to be completed when reopening registration. These tasks should also be completed in the Staging environment to enable testing there.

### Complete eligibility related changes

If there are any new eligibility requirements for the new Cohort then changes will need to be made to the `FundingEligility` service. If additional information is required to determine eligibility then additional questions and screens may need addition to the registration wizard.

Funding Eligibility occurs once the user has finished questions related to their application, selected their NPQ and their provider. This information is then fed into `FundingEligibility`. This service then determines the user's eligibility for government funding and will provide a boolean funded status along with a `funding_eligiblity_status_code` which encodes the reason why a user may not have been funded.

### Add the new Cohort

Add the Cohort which users will be applying to via the Admin area (Admin -> Cohorts).

This should either be 'capped' or 'zero' funding as appropriate - 'full funding' is a legacy concept referring to past cohorts when all applicants were funded and there were no eligibility criteria.

### Add Schedules to the new Cohort

Add Schedules via the Admin area (Admin -> Cohorts -> _new cohort_) - these should follow the schedules used for previous cohorts.

The Schedule's `Applies from` field is used to set the earliest date a declaration will be accepted for a schedule

_Note: at this time there are 3 unused fields on schedules, 'Acceptance start', 'Acceptance end', 'Applies to' - these related to future work which has not yet happened._

### Add Statements and Contracts to the Cohort

Statements and contracts are required in order to receive [declarations](declarations_and_statements.md) but are not required for a Cohort to accept registrations. If a lead provider submits declarations before the statements and contracts have been set up, or after the final output statement has been paid then the declaration will be reject.

To add statements and contracts you click the 'Create statements from CSV' button when viewing the new Cohort in the Admin area (Admin -> Cohorts)

Two CSVs are required to create statements and their contracts.
* the Statements CSV has one row per month, per lead provider and supplies the statement dates and whether it is an output statement
* the Contracts CSV specifies the contract fees for each of the courses - _this should have dummy values for the version tested on staging_

Examples are shown on the Admin screen

### Add milestones to Schedules

Add the milestones to the Schedules - this needs to happen after the statements have been set up. Milestones link between schedules with their expected declaration types and the statements it is expected these declarations will be received by.

These can be added from the Admin area (Admin -> Cohorts -> individual cohort -> individual schedule -> Add milestone button) and are used to provide the 'Expected declarations' column in the declaration statements when viewing a statement.

## Re-opening

Registration is controlled via the `Registration open` feature flag which can be toggled via the Admin->Feature flags section.

When registration is open, users can apply for NPQs and when it is not they are shown the registration closed screen, which also allows users to sign up to be notified when registration reopens (see [RegistrationInterest](../app/models/registration_interest.rb)). The list is accessed via the Admin area, Admin -> Closed registrations -> Users who’ve requested emails about registration reopening.

NPQ also has a concept of 'Closed registrations' - these are users we allow to register when the `Registration open` feature flag is off. A user needs to be added to the list of closed registration users (see Admin -> Closed registrations ->
Users who can access the service when it’s closed) and the "Closed registration enabled" Feature flag in Admin -> Feature flags turned on. If the `Registration open` flag is 'on' then the registration is open for everyone and this flag has no effect.
