# Schedules and milestone dates

<div class="govuk-warning-text">
  <span class="govuk-warning-text__icon" aria-hidden="true">!</span>
  <strong class="govuk-warning-text__text">
    <span class="govuk-visually-hidden">Warning</span>
    Providers must submit declarations in line with terms set out in their contracts.
  </strong>
</div>

[WARNING TEXT] Providers should [MUST?] submit declarations in line with terms set out in their contracts. 

DfE makes payment to providers in line with agreed contractual schedules and training criteria.

NPQ courses can vary in length, and so can each have a different number of milestones.

## How the API assigns schedules

The API will automatically assign schedules to participants depending on when course applications are accepted by providers.

The API does not apply milestone validation to those on NPQ schedules. The API will accept any declarations submitted after the first milestone period has started for a given schedule.

For example, if a participant is on an npq-leadership-autumn schedule, the API will accept any type of declaration (including started, retention-{x} or completed) after the schedule start date.

[INSET TEXT] We advise providers to keep schedule data independent from any experience logic in their systems. Schedules and cohorts are financial concepts specific to the CPD service and payments.

## Concepts and definitions

| Concept | Definition | 
|-----|-----|
| Schedule | The timeframe in which a participant starts a particular NPQ course, which determines milestone dates |
| Milestone | Contractual retention periods during which providers must submit relevant declarations evidencing training delivery and participant retention |
| Milestone dates | The deadline date a valid declaration can be made for a given milestone in order for DfE to be liable to make a payment the following month. Milestone dates are dependent on the participant’s schedule |
| Milestone period | The period of time between the milestone start date and deadline date |
| Output payment | The sum of money paid by DfE to providers per valid declaration
| Payment date | The date DfE will make payment for valid declarations submitted by providers for a given milestone |
| Milestone validation | The API’s process to validate declarations submitted by providers for participants in standard training schedules | 

## NPQ schedules 

The API will automatically assign schedules to participants on specialist NPQ courses depending on when applications are accepted by providers.

Specialist NPQs will be assigned to one of the following schedule identifiers:

* npq-specialist-autumn
* npq-specialist-spring

Leadersip NPQs will be assigned to one of the following schedule identifiers:

* npq-leadership-autumn
* npq-leadership-spring

### When the API will accept declarations 

#### 2024/25 academic year 

| Training start date | Submit declarations from | 
|---|---|
| Before 31 December 2024 | 1 October 2024 |
| From 1 January 2025 | 1 January 2025

#### 2023/24 academic year

| Training start date | Submit declarations from | 
|---|---|
| Before 31 December 2023 | 1 October 2023 |
| From 1 January 2024 | 1 January 2024

#### 2022/23 academic year

| Training start date | Submit declarations from | 
|---|---|
| Before 31 December 2022 | 1 October 2022 |
| From 1 January 2023 | 1 January 2023

View upcoming financial statement payment dates [ADD LINK]

## Early headship coaching offer (EHCO) and addtional support offer (ASO) schedules

EHCO and ASO participant schedules must reflect the month the participant starts their course.

For example, for participants starting an EHCO in December 2024, providers must make sure they're assigned the npq-ehco-december schedule.

EHCO schedules include:

* [npq-ehco-november](/api/guidance/app/views/api/guidance/submit_view_and_void_declarations)
* npq-ehco-december
* npq-ehco-march
* npq-ehco-june

ASO schedules are only available for the 2021 cohort, and include:

* npq-aso-november
* npq-aso-december
* npq-aso-march
* npq-aso-june