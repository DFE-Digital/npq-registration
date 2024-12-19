[< Back to Navigation](../README.md)

# Funding

## Funding eligibility during registration

TODO: to be completed by NPQ reg team

## Accepting an application

When accepting an application we evaluate the `funded_place` attribute passed in the payload against the `funding_cap` of the cohort and `eligible_for_funding` status of the application:

- The `funded_place` attribute in the accept application payload will be evaluated only for cohorts that have a `funding_cap`. 
- The `funded_place` must be `true` or `false` if the cohort has a `funding_cap`.

When accepting an application with a `funded_place`:

- The `funded_place` can be `true` or `false` if the application is `eligible_for_funding`.
- The `funded_place` can only be `false` if the application is not `eligible_for_funding`.

## Changing the funded place of an application

Lead providers can change the `funded_place` of an application via the API:

- The application must be `accepted`.
- The application must be `eligible_for_funding` if changing to `true`.
- The cohort of the application must have a `funding_cap`.
- If changing `funded_place` to `false` the application must have no `eligible`, `payable`, `paid` or `submitted` declarations.

## Previously funded

An application is considered `previously_funded` if:

- Another application exists with an equivalent course (as determined by `rebranded_alternative_courses`).
  - If the application course is not `npq-additional-support-offer` or `npq-early-headship-coaching-offer` it must be the same course.
  - If the application course is `npq-additional-support-offer` or `npq-early-headship-coaching-offer` it can be an application with either of these two courses.
- The other application is `accepted` and `eligible_for_funding`.
- The `funded_place` of the application is either not set (`nil`, i.e. prior to 2024) or is `true`.

## Application serialization/eligible for funding

When an application is serialized we determine the `eligible_for_funding` state by inspecting the user eligibility and if the application has been `previously_funded`.

An application is `eligible_for_funding` if:

- They have no `previously_funded` applications.
- They are `eligible_for_funding`.

## Creating a declaration

On creating a new declaration, it is marked as `eligible` if:

- There are no `previously_funded` applications.
- They are `eligible_for_funding` and `funded_place` is not set (`nil`, i.e. prior to 2024) or is `true`.

## Pre-2024 funded place behaviour

Prior to 2024 we only calculated eligibility for declarations using the `eligible_for_funding` attribute (there was no notion of `funded_place`). Similarly, we only checked only `eligible_for_funding` during the `previously_funded` method as well.

See [ECF #4871](https://github.com/DFE-Digital/early-careers-framework/pull/4871) for how `funded_place` was originally introduced in ECF (and later replicated in NPQ reg) for more details.

