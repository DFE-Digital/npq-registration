# Definitions and states

## Key concepts

| Concept | Definition
|---------|------------|
| application | The application a person makes to be trained on an NPQ course. Applications include funding details |
| participant | A person registered for an NPQ course |
| cohort | The grouping of participants who begin their course in a given academic year under a given funding contract. For example, a participant who started their training in the 2021/2022 academic year will be in the 2021 cohort. This is because their funding comes from the 2021/2022 call-off contract. In most cases providers cannot change a participant’s cohort once they’ve started their training |
| schedule | The expected timeframe in which a participant will complete their NPQ course. Schedules include defined milestone dates [ADD LINK] against which DfE validates the declarations submitted by providers |
| course_identifier | The NPQ course a participant applies for and is registered for |
| outcome | The assessment result a participant achieves at the end of an NPQ course |
|declaration | The notification submitted by providers via the API to trigger output payments from DfE. Declarations are submitted where there is evidence of a participant’s engagement in training for a given milestone period |
| statement | A record of output payments (based on declarations), service fees and any adjustments DfE may pay lead providers at the end of a contractually agreed payment period. Statements sent to providers by DfE at the end of milestone periods can be used for invoicing purposes |

## Data states

This API uses a ‘state’ model to reflect the NPQ participant journey, meet contractual requirements for how providers should report participants’ training and how DfE will pay for this training.

### Application states

Application states are defined by the status attribute. 

A application’s status value will determine whether a provider can:

* accept or reject applications [ADD LINK]

* submit a declaration [ADD LINK]. For example, notifying DfE that a participant has started their training 

| Status | Definition | Action | 
|------|-------|-------|
| pending | Applications which have been made for an NPQ course | Providers can only accept or reject pending applications |
| accepted | Applications which have been accepted by a provider | Providers can submit declarations and update participant data only for those who have had their application accepted |
| rejected | Applications which have been rejected by a provider, or which have been accepted by another provider | Providers cannot submit any API requests for participants who have had their application rejected |

View more detailed specifications for the NPQ application schema [ADD LINK]

### Participant states

Participant states are defined by the training_status attribute. 

A participant’s training_status value will determine whether a provider can:

* update their details [ADD LINK]. For example, notifying DfE that a participant has withdrawn from the course 

* submit a declaration [ADD LINK]. For example, notifying DfE that a participant has started their training 

| Training status | Definition | Action |
|------|-------|-----|
| active | Participants currently in training | Providers can update participant data and submit declarations for active participants |
| deferred | Participants who have deferred training | Providers cannot update participant data or submit declarations for deferred participants. Providers must notify DfE when the participant resumes training [ADD LINK] |
| withdrawn | Participants who have withdrawn from training | Providers cannot update participant data for withdrawn participants. Providers can only submit declarations for withdrawn participants if the declaration_date is backdated to before the withdrawal_date |

View more detailed specifications for the NPQ participant schema [ADD LINK]

### Declaration states

Declaration states are defined by the state attribute. 

Providers must submit declarations [ADD LINK] to confirm a participant has engaged in training within a given milestone period. A declaration’s state value will reflect if and when DfE will pay providers for the training delivered.

| State | Definition | Action |
|---|----|-----|
| submitted | A declaration associated with to a participant who has not yet been confirmed to be eligible for funding | Providers can view and void submitted declarations |
| eligible | A declaration associated with a participant who has been confirmed to be eligible for funding | Providers can view and void eligible declarations |
| ineligible | A declaration associated with a participant who is not eligible for funding or a duplicate submission for a given participant | Providers can view and void ineligible declarations |
| payable | A declaration that has been approved and is ready for payment by DfE | Providers can view and void payable declarations |
| awaiting_clawback | A paid declaration that has since been voided by a provider | Providers can only view awaiting_clawback declarations |
| clawed_back | An awaiting_clawback declaration that has since had its value deducted from payment by DfE to a provider | Providers can only view clawed_back declarations |

View more detailed specifications for the declaration schema [ADD LINK]