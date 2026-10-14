# Declarations and Statements

This document describes statements, their lifecycle and when declarations are allocated to them for payment.

## Declarations

When a Participant attains a particular milestone during their NPQ then Lead Providers create a Declaration via the API notifying the NPQ service of attainment of that milestone.

If the participant is funded then the Declaration will be attached to the next available output Statement for payment. The statement selected will be the one which corresponds to the Applications current Lead Provider and Cohort.

In the event a Participant is transferred between Lead Providers, then their Declarations for different milestones may be allocated to different Lead Providers. Lead Providers are able to see but not modify the Declarations from other Lead Providers for the transferred Participant.

## Statements

NPQ service has 1 statement per Lead Provider per Cohort per month for the contract period. Only Statements for certain 'nominated' months are intended for Payment - these are referred to as either output Statements or payment run statements. Others non payment statements are referred to as non-output Statements or non-payment run statements.

Statements have an 'output_fee' on/off switch which controls whether they are an 'output Statement' or not.

Each statement has 2 dates

* Deadline date - which is the latest point when Declarations can be attached to that statement
  This is normally the 25th of the month prior to the month the statement is for.
* Payment date - the date when a statement is intended to be paid at - normally this is the 25th of the month the statement is for.

Statements move through 3 states

* Open - these are future statements which may receive declarations (if they have output_fee set)
* Payable - when a statements Deadline Date is passed it is automatically marked Payable and no more declarations made via the Lead Providers API will be added to the statement.
* Paid - when a statement has been reviewed and is confirmed correct then it is marked Paid via the Admin area and can no longer be modified.

## Updating Statements and their Declarations

Changes can be made to Statements but with certain contraints.

### Changing Deadline and Payment Dates

* Deadline dates can only be changed for Open statements, ie Statements whose deadline date has not yet passed
* Payment dates can also only be changed for Open statements.

### Moving Declarations between Statements

In the event a Statement needs to be changed from an output Statement to a non-output statement or vice versa, then this can be performed by Super Admins via the Admin area.

#### Open statements

Open statements can be both made into output statements, and made into non-output statements

* When turning output_fee On for a Statement, then any declarations on the next output statement which be moved forward onto the Statement being made into an output statement. If there is no later output statement then no Declarations will be moved.
* When turning output_fee Off for a Statement, then any declarations on the statement being made into a non-output statement will be moved onto the next available output statement. If there is not a later output statement then the change will only be allowed if there are no Declarations or Milestones attached to the statement being turned off.

#### Payable statements

For the 'current' payable statement - ie the statements deadline date has passed but the payment date has not yet passed. Any changes to a Payable statement will require additional confirmation via an extra checkbox which will only shown when changing Payable statements.

* Output fee can be turned On making this statement into an Output statement. Declarations attached to a later Output statement will be moved forward onto this statement.
* Output fee can be turned Off making this statement into a non-output statement. Any Declarations on this statement will be moved onto a later Output statement if available. If there are Declarations on this statement but there is not a later output statement available then the change will not be allowed.

Currently statements which are not being Paid do not get marked paid and remain marked as 'Payable' even after their payment date is passed.

* Output fee cannot be turned On for past Payable statements because the Payment date has already passed
* Output fee _can_ be turned Off for past Payable statements and any declarations against the statement will be moved backwards onto the first available Unpaid output statement (ie Open or Payable) whose payment date has not yet been past.

#### Paid statements

These cannot be changed because they have already been marked as Paid, ie finalised.

