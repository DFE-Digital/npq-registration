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
      <td class="govuk-table__cell">The expected timeframe in which a participant will complete their NPQ course. Schedules include defined [milestone dates](ADD LINK) against which DfE validates the declarations submitted by providers</td>
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
  </tbody>
</table>

## Application data states

This API uses a `state` model to reflect the NPQ participant journey, meet contractual requirements for how providers should report participants’ training and how DfE will pay for this training.

Application states are defined by the `status` attribute. 

A application’s status value will determine whether a provider can:

* [accept or reject applications](ADD LINK)

* [submit a declaration](ADD LINK). For example, notifying DfE that a participant has started their training 

<table class="govuk-table">
<caption class="govuk-table__caption govuk-table__caption--m">Application status values</caption>
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">Status</th>
      <th scope="col" class="govuk-table__header govuk-table__header--numeric">Definition</th>
      <th scope="col" class="govuk-table__header govuk-table__header--numeric">What providers can do</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>pending</code></th>
      <td class="govuk-table__cell govuk-table__cell--numeric">Applications which have been made for an NPQ course</td>
      <td class="govuk-table__cell govuk-table__cell--numeric">Accept or reject applications</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>accepted</code></th>
      <td class="govuk-table__cell govuk-table__cell--numeric">Applications which have been accepted by a provider</td>
      <td class="govuk-table__cell govuk-table__cell--numeric">Submit declarations and update participant data</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>rejected</code></th>
      <td class="govuk-table__cell govuk-table__cell--numeric">Applications which have been rejected by a provider, or which have been accepted by another provider</td>
      <td class="govuk-table__cell govuk-table__cell--numeric">No action required</td>
    </tr>
  </tbody>
</table>

[View more detailed specifications for the NPQ application schema](ADD LINK)

## Participant data states

Participant states are defined by the `training_status` attribute. 

A participant’s `training_status` value will determine whether a provider can:

* [update their details](ADD LINK). For example, notifying DfE that a participant has withdrawn from the course 

* [submit a declaration](ADD LINK). For example, notifying DfE that a participant has started their training 

<table class="govuk-table">
<caption class="govuk-table__caption govuk-table__caption--m">Training status values</caption>
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">Training status</th>
      <th scope="col" class="govuk-table__header govuk-table__header--numeric">Definition</th>
      <th scope="col" class="govuk-table__header govuk-table__header--numeric">What providers can do</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>active</code></th>
      <td class="govuk-table__cell govuk-table__cell--numeric">Participants currently in training</td>
      <td class="govuk-table__cell govuk-table__cell--numeric">Update participant data and submit declarations</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>deferred</code></th>
      <td class="govuk-table__cell govuk-table__cell--numeric">Participants who've deferred training</td>
      <td class="govuk-table__cell govuk-table__cell--numeric">Notify DfE when the participant [resumes training](ADD LINK)</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>withdrawn</code></th>
      <td class="govuk-table__cell govuk-table__cell--numeric">Participants who have withdrawn from training</td>
      <td class="govuk-table__cell govuk-table__cell--numeric">Submit declarations for withdrawn participants if the <code>declaration_date</code> is backdated to before the <code>withdrawal_date</code></td>
    </tr>
  </tbody>
</table>

[View more detailed specifications for the NPQ participant schema](ADD LINK)

## Declaration data states

Declaration states are defined by the `state` attribute. 

Providers must [submit declarations](ADD LINK) to confirm a participant has engaged in training within a given milestone period. A declaration’s `state` value will reflect if and when DfE will pay providers for the training delivered.

<table class="govuk-table">
<caption class="govuk-table__caption govuk-table__caption--m">Declaration status values</caption>
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">State</th>
      <th scope="col" class="govuk-table__header govuk-table__header--numeric">Definition</th>
      <th scope="col" class="govuk-table__header govuk-table__header--numeric">What providers can do</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>submitted</code></th>
      <td class="govuk-table__cell govuk-table__cell--numeric">A declaration associated with to a participant who has not yet been confirmed to be eligible for funding</td>
      <td class="govuk-table__cell govuk-table__cell--numeric">View and void</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>eligible</code></th>
      <td class="govuk-table__cell govuk-table__cell--numeric">A declaration associated with a participant who has been confirmed to be eligible for funding</td>
      <td class="govuk-table__cell govuk-table__cell--numeric">View and void</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>ineligible</code></th>
      <td class="govuk-table__cell govuk-table__cell--numeric">A declaration associated with a participant who is not eligible for funding or a duplicate submission for a given participant</td>
      <td class="govuk-table__cell govuk-table__cell--numeric">View and void</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>payable</code></th>
      <td class="govuk-table__cell govuk-table__cell--numeric">A declaration that has been approved and is ready for payment by DfE</td>
      <td class="govuk-table__cell govuk-table__cell--numeric">View and void</td>
    </tr>
     <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>voided</code></th>
      <td class="govuk-table__cell govuk-table__cell--numeric">A declaration that has been retracted by a provider</td>
      <td class="govuk-table__cell govuk-table__cell--numeric">View</td>
    </tr>
     <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>paid</code></th>
      <td class="govuk-table__cell govuk-table__cell--numeric">A declaration that has been paid for by DfE</td>
      <td class="govuk-table__cell govuk-table__cell--numeric">View and void</td>
    </tr>
     <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>awaiting_clawback</code></th>
      <td class="govuk-table__cell govuk-table__cell--numeric">A <code>paid</code> declaration that has since been voided by a provider</td>
      <td class="govuk-table__cell govuk-table__cell--numeric">View</td>
    </tr>
     <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>clawed_back</code></th>
      <td class="govuk-table__cell govuk-table__cell--numeric">An <code>awaiting_clawback</code> declaration that has since had its value deducted from payment by DfE to a provider</td>
      <td class="govuk-table__cell govuk-table__cell--numeric">View</td>
    </tr>
  </tbody>
</table>

[View more detailed specifications for the declaration schema](ADD LINK)