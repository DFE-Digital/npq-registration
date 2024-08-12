# Data states

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
      <th scope="row" class="govuk-table__header"><code>application</code></th>
      <td class="govuk-table__cell">The application a person makes to be trained on an NPQ course. Applications include funding details</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>participant</code></th>
      <td class="govuk-table__cell">A person registered for an NPQ course</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>schedule</code></th>
      <td class="govuk-table__cell">The expected timeframe in which a participant will complete their NPQ course. Schedules include defined [milestone dates](/api/guidance/schedules-and-milestone-dates) against which DfE validates the declarations submitted by providers</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>course_identifier</code></th>
      <td class="govuk-table__cell">The NPQ course a participant applies for and is registered for</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>outcome</code></th>
      <td class="govuk-table__cell">The assessment result a participant achieves at the end of an NPQ course</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>declaration</code></th>
      <td class="govuk-table__cell">The notification submitted by providers via the API to trigger output payments from DfE. Declarations are submitted where there is evidence of a participant’s engagement in training for a given milestone period</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>statement</code></th>
      <td class="govuk-table__cell">A record of output payments (based on declarations), service fees and any adjustments DfE may pay lead providers at the end of a contractually agreed payment period. Statements sent to providers by DfE at the end of milestone periods can be used for invoicing purposes</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>funded place</code></th>
      <td class="govuk-table__cell">The way for DfE and providers to identify participants who are eligible for funding and for whom there is funding available</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>funding cap</code></th>
      <td class="govuk-table__cell">The maximum number of places each provider can offer per NPQ that DfE will pay for from the 2024/25 academic year onwards</td>
    </tr>
  </tbody>
</table>

## Application data states

This API uses a `state` model to reflect the NPQ participant journey, meet contractual requirements for how providers should report participants’ training and how DfE will pay for this training.

Application states are defined by the `status` attribute.

An application’s status value will determine whether a provider can:

* accept or reject applications

* submit a declaration. For example, notifying DfE that a participant has started their training

<table class="govuk-table">
  <caption class="govuk-table__caption govuk-table__caption--m">Application status values</caption>
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">Status</th>
      <th scope="col" class="govuk-table__header govuk-table__header">Definition</th>
      <th scope="col" class="govuk-table__header govuk-table__header">What providers can do</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>pending</code></th>
      <td class="govuk-table__cell govuk-table__cell">Applications which have been made for an NPQ course</td>
      <td class="govuk-table__cell govuk-table__cell">Accept or reject applications</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>accepted</code></th>
      <td class="govuk-table__cell govuk-table__cell">Applications which have been accepted by a provider</td>
      <td class="govuk-table__cell govuk-table__cell">Submit declarations and update participant data</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>rejected</code></th>
      <td class="govuk-table__cell govuk-table__cell">Applications which have been rejected by a provider, or which have been accepted by another provider</td>
      <td class="govuk-table__cell govuk-table__cell">No action required</td>
    </tr>
  </tbody>
</table>

## Participant data states

Participant states are defined by the `training_status` attribute.

A participant’s `training_status` value will determine whether a provider can:

* update their details. For example, notifying DfE that a participant has withdrawn from the course

* submit a declaration. For example, notifying DfE that a participant has started their training

<table class="govuk-table">
  <caption class="govuk-table__caption govuk-table__caption--m">Training status values</caption>
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">Training status</th>
      <th scope="col" class="govuk-table__header govuk-table__header">Definition</th>
      <th scope="col" class="govuk-table__header govuk-table__header">What providers can do</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>active</code></th>
      <td class="govuk-table__cell govuk-table__cell">Participants currently in training</td>
      <td class="govuk-table__cell govuk-table__cell">Update participant data and submit declarations</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>deferred</code></th>
      <td class="govuk-table__cell govuk-table__cell">Participants who've deferred training</td>
      <td class="govuk-table__cell govuk-table__cell">Notify DfE when the participant [resumes training](https://npq-registration-review-1388-web.test.teacherservices.cloud/api/docs/v3#/NPQ%20Participants/put_api_v3_participants_npq__id__resume)</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>withdrawn</code></th>
      <td class="govuk-table__cell govuk-table__cell">Participants who have withdrawn from training</td>
      <td class="govuk-table__cell govuk-table__cell">Submit declarations for withdrawn participants if the <code>declaration_date</code> is backdated to before the <code>withdrawal_date</code></td>
    </tr>
  </tbody>
</table>

## Declaration data states

Declaration states are defined by the `state` attribute.

Providers must submit declarations to confirm a participant has engaged in training within a given milestone period. A declaration’s `state` value will reflect if and when DfE will pay providers for the training delivered.

<table class="govuk-table">
  <caption class="govuk-table__caption govuk-table__caption--m">Declaration status values</caption>
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">State</th>
      <th scope="col" class="govuk-table__header govuk-table__header">Definition</th>
      <th scope="col" class="govuk-table__header govuk-table__header">What providers can do</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>submitted</code></th>
      <td class="govuk-table__cell govuk-table__cell">A declaration associated with to a participant who has not yet been confirmed to be eligible for funding</td>
      <td class="govuk-table__cell govuk-table__cell">View and void</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>eligible</code></th>
      <td class="govuk-table__cell govuk-table__cell">A declaration associated with a participant who has been confirmed to be eligible for funding</td>
      <td class="govuk-table__cell govuk-table__cell">View and void</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>ineligible</code></th>
      <td class="govuk-table__cell govuk-table__cell">A declaration associated with a participant who is not eligible for funding or a duplicate submission for a given participant</td>
      <td class="govuk-table__cell govuk-table__cell">View and void</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>payable</code></th>
      <td class="govuk-table__cell govuk-table__cell">A declaration that has been approved and is ready for payment by DfE</td>
      <td class="govuk-table__cell govuk-table__cell">View and void</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>voided</code></th>
      <td class="govuk-table__cell govuk-table__cell">A declaration that has been retracted by a provider</td>
      <td class="govuk-table__cell govuk-table__cell">View</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>paid</code></th>
      <td class="govuk-table__cell govuk-table__cell">A declaration that has been paid for by DfE</td>
      <td class="govuk-table__cell govuk-table__cell">View and void</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>awaiting_clawback</code></th>
      <td class="govuk-table__cell govuk-table__cell">A <code>paid</code> declaration that has since been voided by a provider</td>
      <td class="govuk-table__cell govuk-table__cell">View</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>clawed_back</code></th>
      <td class="govuk-table__cell govuk-table__cell">An <code>awaiting_clawback</code> declaration that has since had its value deducted from payment by DfE to a provider</td>
      <td class="govuk-table__cell govuk-table__cell">View</td>
    </tr>
  </tbody>
</table>
