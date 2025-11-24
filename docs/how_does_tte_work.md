[< Back to Navigation](../README.md)

# What is TTE?

Teacher Training Entitlement is a DfE service that allows teachers to apply for funded training as part of the CPD program.

1. [The Registration Wizard](#the-registration-wizard)
1. [Courses](#courses)
1. [Lead Providers](#lead-providers)
1. [Funding Eligibility](#funding-eligibility)
1. [Targeted Support Funding](#targeted-support-funding)

# How does it work?

## The Registration Wizard

The Registration Wizard is at the core of the digital service. Participants must answer a series of questions in order to complete their application.

This core flow is a loop through the registration_wizard#show and registration_wizard#update actions. The user visits a page, the corresponding Form object is loaded with the user's store from their session, and the form is rendered. This occurs within registration_wizard#show.

When the user submits the form, the corresponding Form object is loaded with the user's store from their session and the form is validated. If the form is valid, the user's store is updated with the form's attributes and the user is redirected to the next step in the wizard. If the form is invalid, the user is redirected back to the form with the errors displayed.

### The Forms

Form objects are found within [app/forms](app/forms). Each Form Object is responsible for validating the user's input and updating the user's store with the form's attributes.

It defines the question name, validations, and the next_step and previous_step.

### The Store

The store is a session based store of the user's current application state. It is a hash that is stored in the user's session and is updated as the user progresses through the wizard. It is accessed by calling `wizard.store` on or within a form. The Query Store (detailed below) provides a way to access the store in a structured way.

### RegistrationQueryStore

The RegistrationQueryStore service is a wrapper around the store hash, providing helper methods to access store information.

## Courses

The Course model represents the different NPQs that are available to apply for. Each course has an `identifier` which is used to identify the course in the API.

## Lead Providers

The LeadProvider model represents the different Lead Providers that are able to provide training on the various NPQ courses. Each course has a different set of LeadProviders that can be selected. This is determined by calling `LeadProvider.for(course:)` when the user is presented their list of Lead Providers to choose from.

## Funding Eligibility

Funding Eligibility occurs once the user has finished questions related to their application, selected their NPQ and their provider. This information is then fed into `FundingEligibility`. This service then determines the user's eligibility for government funding and will provide a boolean funded status along with a `funding_eligiblity_status_code` which encodes the reason why a user may not have been funded.
