# Schedules and milestone dates

<div class="govuk-warning-text">
  <span class="govuk-warning-text__icon" aria-hidden="true">!</span>
  <strong class="govuk-warning-text__text">
    <span class="govuk-visually-hidden">Warning</span>
    Providers must submit declarations in line with terms set out in their contracts.
  </strong>
</div>

DfE pays providers in line with agreed contractual schedules and training criteria.

NPQ courses can vary in length. Because of this, they can have a different number contractual retention periods during which providers must submit relevant declarations evidencing training delivery and participant retention.

## How the API assigns schedules

The API will automatically assign schedules to participants depending on when course applications are accepted by providers.

The API does not apply milestone validation to those on NPQ schedules. The API will accept any declarations submitted after the first milestone period has started for a given schedule.

For example, if a participant is on an `npq-leadership-autumn` schedule, the API will accept any type of declaration (including `started`, `retention-{x}` or `completed`) after the schedule start date.

<div class="govuk-inset-text">
  We advise providers to keep schedule data independent from any experience logic in their systems.
</div>

## Concepts and definitions

<table class="govuk-table">
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">Concept</th>
      <th scope="col" class="govuk-table__header">Definition</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">Schedule</th>
      <td class="govuk-table__cell">The timeframe in which a participant starts a particular NPQ course, which determines milestone dates</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">Milestone</th>
      <td class="govuk-table__cell">Contractual retention periods during which providers must submit relevant declarations evidencing training delivery and participant retention</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">Milestone dates</th>
      <td class="govuk-table__cell">The deadline date a valid declaration can be made for a given milestone in order for DfE to be liable to make a payment the following month. Milestone dates are dependent on the participant’s schedule</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">Milestone period</th>
      <td class="govuk-table__cell">The period of time between the milestone start date and deadline date</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">Output payment</th>
      <td class="govuk-table__cell">The sum of money paid by DfE to providers per valid declaration</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">Payment date</th>
      <td class="govuk-table__cell">The date DfE will make payment for valid declarations submitted by providers for a given milestone</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">Milestone validation</th>
      <td class="govuk-table__cell">The API’s process to validate declarations submitted by providers for participants in standard training schedules</td>
    </tr>
  </tbody>
</table>

## NPQ schedules 

The API will automatically assign schedules to participants on specialist NPQ courses depending on when applications are accepted by providers.

Specialist NPQs will be assigned to one of the following schedule identifiers:

* `npq-specialist-autumn`
* `npq-specialist-spring`

Leadersip NPQs will be assigned to one of the following schedule identifiers:

* `npq-leadership-autumn`
* `npq-leadership-spring`

## When the API will accept NPQ declarations 

<table class="govuk-table">
  <caption class="govuk-table__caption govuk-table__caption--m">2024/25 academic year</caption>
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">Training start date</th>
      <th scope="col" class="govuk-table__header">Submit declarations from</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">Before 31 December 2024</th>
      <td class="govuk-table__cell">1 October 2024</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">From 1 January 2025</th>
      <td class="govuk-table__cell">1 January 2025</td>
    </tr>
  </tbody>
</table>

<table class="govuk-table">
  <caption class="govuk-table__caption govuk-table__caption--m">2023/24 academic year</caption>
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">Training start date</th>
      <th scope="col" class="govuk-table__header">Submit declarations from</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">Before 31 December 2023</th>
      <td class="govuk-table__cell">1 October 2023</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">From 1 January 2024</th>
      <td class="govuk-table__cell">1 January 2024</td>
    </tr>
  </tbody>
</table>

<table class="govuk-table">
  <caption class="govuk-table__caption govuk-table__caption--m">2022/23 academic year</caption>
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">Training start date</th>
      <th scope="col" class="govuk-table__header">Submit declarations from</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">Before 31 December 2022</th>
      <td class="govuk-table__cell">1 October 2022</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header">From 1 January 2023</th>
      <td class="govuk-table__cell">1 January 2023</td>
    </tr>
  </tbody>
</table>

## Early headship coaching offer (EHCO) and addtional support offer (ASO) schedules

EHCO and ASO participant schedules must reflect the month the participant starts their course.

For example, for participants starting an EHCO in December 2024, providers must make sure they're assigned the `npq-ehco-december` schedule.

EHCO schedules include:

* `npq-ehco-november`
* `npq-ehco-december`
* `npq-ehco-march`
* `npq-ehco-june`

ASO schedules are only available for the 2021 cohort, and include:

* `npq-aso-november`
* `npq-aso-december`
* `npq-aso-march`
* `npq-aso-june`
