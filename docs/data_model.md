[< Back to Navigation](../README.md)

# Data model

> This document will undoubtedly change and grow as we develop our understanding of the services that this application encapsulates.

## 1. Introduction

This document provides an overview of the data model for the NPQ application. It details the primary entities, their relationships, and the data flow within the application. This model is essential for developers, database administrators, and stakeholders to understand how data is structured, stored, and retrieved.

## 2. Purpose of the Data Model

The data model for storing NPQ data is designed to:

- Facilitate efficient data storage and retrieval.
- Enable the business logic of the application by structuring data relationships.
- Support data integrity, scalability, and performance optimization.
- Serve as a guide for developers during the implementation and maintenance phases.

## 3. Entity-Relationship Diagram (ERD)

This diagram represents our current understanding of the data models:

```mermaid
erDiagram
    Application }|--|| User : ""
    Application }|--|| LeadProvider : ""
    Application }|--|| Course : ""
    Application }|--|| Schedule : ""
    Application }o--o| School : ""
    Application }o--o| PrivateChildcareProvider : ""
    Application }o--o| IttProvider : ""

    Declaration }|--|| Application : ""

    Statement }|--|| LeadProvider : ""
    Statement }|--|| Cohort : ""

    StatementItem }|--|| Statement : ""
    StatementItem }|--|| Declaration : ""

    Contract }|--|| Statement : ""
    Contract }|--|| Course : ""
    Contract }|--|| ContractTemplate : ""

    ParticipantOutcome }|--|| Declaration : ""

    Course }|--|| CourseGroup : ""
    Schedule }|--|| CourseGroup : ""
    Schedule }|--|| Cohort : ""

    ParticipantIdChange }|--|| User : ""

    ApiToken }|--|| LeadProvider : ""

    User {
        uuid id
        string email
        string full_name
        string teacher_reference_number
        datetime updated_at
    }

    LeadProvider {
        uuid id
        string name
    }

    Course {
        uuid id
        uuid course_group_id
        string identifier
    }

    Application {
        uuid id
        uuid course_id
        uuid lead_provider_id
        uuid user_id
        uuid schedule_id
        uuid itt_provider_id
        uuid school_id
        uuid private_childcare_provider_id
        string employer_name
        string employment_role
        string funding_choice
        string headteacher_status
        string ineligible_for_funding_reason
        string school_urn
        string lead_provider_approval_status
        string training_status
        boolean works_in_school
        boolean eligible_for_funding
        boolean targeted_delivery_funding_eligibility
        string teacher_catchment
        string teacher_catchment_iso_country_code
        string teacher_catchment_country
        boolean lead_mentor
        datetime accepted_at
        datetime updated_at
    }

    Cohort {
        uuid id
        integer start_year
    }

    ParticipantOutcome {
        uuid id
        string state
        date completion_date
        uuid declaration_id
        datetime created_at
    }

    Declaration {
        uuid id
        uuid application_id
        string state
        string declaration_type
        date declaration_date
        datetime updated_at
    }

    School {
        uuid id
        string urn
        string ukprn
    }

    Statement {
        uuid id
        enum month
        integer year
        date deadline_date
        uuid cohort_id
        uuid lead_provider_id
        datetime marked_as_paid_at
        decimal reconcile_amount
        string state
    }

    StatementItem {
        uuid id
        uuid statement_id
        uuid declaration_id
        string state
    }

    Contract {
        uuid statement_id
        uuid course_id
        uuid contract_template_id
    }

    ContractTemplate {
        boolean special_course
        decimal recruitment_target
        decimal per_participant
        decimal output_payment_percentage
        decimal number_of_payment_periods
        decimal service_fee_percentage
        decimal service_fee_installments
    }

    CourseGroup {
        uuid id
        string name
    }

    Schedule {
        uuid id
        uuid course_group_id
        uuid cohort_id
        string name
        date declaration_starts_on
        date schedule_applies_from
        date schedule_applies_to
        string declaration_type
    }

    ParticipantIdChange {
        uuid id
        uuid user_id
        uuid from_participant_id
        uuid to_participant_id
    }

    ApiToken {
        uuid id
        uuid lead_provider_id
        string hashed_token
        datetime last_used_at
    }
```

### 3.1 Overview of Key Entities and Relationships

1. **Application** - Central to the model, `Application` connects multiple entities:
   - It has a one-to-one relationship with `User`, `LeadProvider`, `Course`, and `Schedule`.
   - It has optional relationships with `School`, `PrivateChildcareProvider`, and `IttProvider`.

   `Application` captures various attributes related to a user's employment, funding eligibility, and application status.

2. **User** - Represents individuals applying for courses. Each `User` has an ID, email, and other identifying details, including a teacher reference number.

3. **LeadProvider** - Provides a source for educational leads or courses. LeadProviders are linked to multiple entities:
   - `Application` to associate a lead provider with specific applications.
   - `Statement` to track declarations and cohorts per provider.
   - `ApiToken` to allow access via API, with security tracking through hashed tokens and last used timestamps.

4. **Course** - Represents educational courses available for application.
   - Linked to `Application` to assign a course to an application.
   - Connected to `CourseGroup` to organize courses by group and associate with `Schedule`.

5. **Schedule** - Details the scheduling for different course groups and cohorts, including key dates like the start and application period for declarations.

6. **Cohort** - Represents a group of participants starting in a given year. It links with:
   - `Schedule` and `Statement`, to track cohorts across schedules and statements.

7. **Declaration and Statement** - These entities track user declarations and statements associated with lead providers:
   - `Declaration` links to `Application` and `ParticipantOutcome`, tracking users' declaration states and types.
   - `Statement` relates to `LeadProvider` and `Cohort` to represent payment deadlines, states, and reconciliation amounts.

8. **Contract and ContractTemplate** - Defines the contractual relationships and terms related to statements and courses:
   - `Contract` links `Statement`, `Course`, and `ContractTemplate`.
   - `ContractTemplate` captures detailed payment and service fee structures.

9. **ParticipantOutcome** - Tracks user outcomes tied to declarations, including the outcome state and completion date.

10. **Auxiliary Entities**
    - `School`, `PrivateChildcareProvider`, and `IttProvider` allow additional relationships with applications.
    - `ApiToken` enables secure API access for lead providers.
    - `ParticipantIdChange` keeps a record of changes in participant IDs for `User`.

#### Diagram Highlights

The relationships in this model are represented by various line symbols:
- `}|--||` indicates a one-to-one relationship.
- `}|--o|` indicates an optional relationship.

This structure allows flexibility in assigning providers, courses, and schedules to applications, enabling complex participant and declaration management within the application

## 4. Data Flow and Key Processes

This data model supports a structured system for NPQ applications, participant declarations, provider statements, and contractual processes. Here's a high-level overview of the data flow and key processes:

### 4.1. **Application Submission Process**

   - **Data Entry**: A user (`User`) submits an `Application` for a `Course` offered by a `LeadProvider`.
   - **Entity Interactions**: When an `Application` is created, it references:
     - The `User` applying.
     - The specific `Course` and `Schedule` (related to timing and cohorts).
     - Optional entities like `School`, `PrivateChildcareProvider`, and `IttProvider`, representing different organizational affiliations or employment details.
   - **Attributes**: The `Application` includes data on eligibility, funding, role, approval, and training status. This information is essential for tracking the participant's suitability and funding options.

   This application data flows to downstream entities that track the participant's progress and outcomes.

```mermaid
erDiagram
    Application }|--|| User : ""
    Application }|--|| Schedule : ""
    Declaration }|--|| Application : ""

    User {
        uuid id
        string email
        string full_name
        string teacher_reference_number
        datetime updated_at
    }

    Application {
        uuid id
        uuid course_id
        uuid lead_provider_id
        uuid user_id
        uuid schedule_id
        uuid itt_provider_id
        uuid school_id
        uuid private_childcare_provider_id
        string employer_name
        string employment_role
        string funding_choice
        string headteacher_status
        string ineligible_for_funding_reason
        string school_urn
        string lead_provider_approval_status
        string training_status
        boolean works_in_school
        boolean eligible_for_funding
        boolean targeted_delivery_funding_eligibility
        string teacher_catchment
        string teacher_catchment_iso_country_code
        string teacher_catchment_country
        boolean lead_mentor
        datetime accepted_at
        datetime updated_at
    }

    Declaration {
        uuid id
        uuid application_id
        string state
        string declaration_type
        date declaration_date
        datetime updated_at
    }

    Schedule {
        uuid id
        uuid course_group_id
        uuid cohort_id
        string name
        date declaration_starts_on
        date schedule_applies_from
        date schedule_applies_to
        string declaration_type
    }
```

### 4.2. **Course Scheduling and Cohort Management**

   - **Data Organization**: Courses (`Course`) are organized into `CourseGroup`s, which are further linked to specific `Schedule`s. `Schedule` connects each `CourseGroup` with `Cohort` entities that denote specific time frames, ensuring applications align with course timings.
   - **Cohort Management**: The `Cohort` entity represents the year or session in which a group of participants starts. Each cohort can be associated with multiple applications and helps manage different program batches.

   This organization ensures that courses are managed and tracked by cohorts and groups, making it easy to allocate schedules and track cohort-specific declarations and outcomes.

```mermaid
erDiagram
    Course }|--|| CourseGroup : ""
    Schedule }|--|| CourseGroup : ""
    Schedule }|--|| Cohort : ""

    Course {
        uuid id
        uuid course_group_id
        string identifier
    }

    Cohort {
        uuid id
        integer start_year
    }

    CourseGroup {
        uuid id
        string name
    }

    Schedule {
        uuid id
        uuid course_group_id
        uuid cohort_id
        string name
        date declaration_starts_on
        date schedule_applies_from
        date schedule_applies_to
        string declaration_type
    }
```

### 4.3. **Declaration and Statement Process**

   - **Declarations**: As users participate in courses, they make progress and fulfill specific requirements represented by `Declaration` entities.
     - **Attributes**: Each `Declaration` has a state (e.g., submitted, approved), type, and declaration date.
     - **Association**: `Declaration` is linked to `Application`, allowing the system to track a participant's journey through different declarations.
     - **Outcome Tracking**: A `ParticipantOutcome` entity links to `Declaration`, capturing the outcome and completion status of the user's declaration.

   - **Statements**: `Statement`s track financial aspects of user declarations for each `LeadProvider` and `Cohort`.
     - **Attributes**: Each `Statement` has attributes for financial reconciliation, deadlines, payment states, and provider-specific data.
     - **Items Tracking**: `StatementItem`s are associated with `Declaration`s and store the state of each declaration as part of the statement.

   This declaration-statement process captures user progress and facilitates reporting for providers, helping reconcile payments and manage declarations.

```mermaid
erDiagram
    ParticipantOutcome }o--|| Declaration : ""

    StatementItem }|--|| Statement : ""
    StatementItem }|--|| Declaration : ""

    Declaration {
        uuid id
        uuid application_id
        string state
        string declaration_type
        date declaration_date
        datetime updated_at
    }

    Statement {
        uuid id
        enum month
        integer year
        date deadline_date
        uuid cohort_id
        uuid lead_provider_id
        datetime marked_as_paid_at
        decimal reconcile_amount
        string state
    }

    StatementItem {
        uuid id
        uuid statement_id
        uuid declaration_id
        string state
    }

    ParticipantOutcome {
        uuid id
        string state
        date completion_date
        uuid declaration_id
        datetime created_at
    }
```

### 4.4. **Contractual and Financial Tracking**

   - **Contracts**: The `Contract` entity defines agreements between the educational system, providers, and courses. It ties into `Statement`, `Course`, and `ContractTemplate`.
   - **Templates**: Each `ContractTemplate` specifies payment terms, including service fees, participant fees, recruitment targets, and payment periods.
   - **Financial Flow**: `ContractTemplate` ensures that each `Contract` and `Statement` aligns with predefined financial terms, facilitating accurate budget and payment management.

   This financial tracking process ensures contractual compliance, accurate billing, and budget management across providers and courses.

```mermaid
erDiagram
    Contract }|--|| Statement : ""
    Contract }|--|| ContractTemplate : ""

    Statement {
        uuid id
        enum month
        integer year
        date deadline_date
        uuid cohort_id
        uuid lead_provider_id
        datetime marked_as_paid_at
        decimal reconcile_amount
        string state
    }

    Contract {
        uuid statement_id
        uuid course_id
        uuid contract_template_id
    }

    ContractTemplate {
        boolean special_course
        decimal recruitment_target
        decimal per_participant
        decimal output_payment_percentage
        decimal number_of_payment_periods
        decimal service_fee_percentage
        decimal service_fee_installments
    }
```

### 4.5. **User and Provider Management**

   - **User ID Management**: `ParticipantIdChange` enables the tracking of changes in user (`User`) identifiers, essential for maintaining a clear user history.
   - **API Access**: `ApiToken` allows `LeadProvider`s secure access to the system via hashed tokens, facilitating data access for providers while ensuring security.

   These auxiliary processes help maintain user data integrity and allow providers secure access to manage applications and declarations.

```mermaid
erDiagram
    ParticipantIdChange }|--|| User : ""
    LeadProvider }|--|| ApiToken : ""

    User {
        uuid id
        string email
        string full_name
        string teacher_reference_number
        datetime updated_at
    }

    LeadProvider {
        uuid id
        string name
    }

    ParticipantIdChange {
        uuid id
        uuid user_id
        uuid from_participant_id
        uuid to_participant_id
    }

    ApiToken {
        uuid id
        uuid lead_provider_id
        string hashed_token
        datetime last_used_at
    }
```

#### Key Data Flow Summary:

1. **Application Creation** ➔ Triggers cohort and schedule associations for user applications.
2. **Declaration Submission** ➔ Captures user progress and outcomes, feeding into statements for financial tracking.
3. **Statement and Contract Processing** ➔ Ensures compliance with financial terms for providers, courses, and user declarations.
4. **Provider and User Management** ➔ Supports secure provider access and accurate user tracking across application processes.

### Overall Workflow

1. **User applies** for a course through an `Application`, selecting relevant schedules and providers.
2. **Declarations** are made based on user progress, feeding into statements and tracking outcomes.
3. **Statements** and **Contracts** manage finances, ensuring terms are met.
4. **Providers** access data through `ApiToken`, while user identifiers are tracked to ensure data accuracy.

## 5. Data Integrity and Constraints

Data integrity and constraints are crucial in this data model to ensure the correctness, consistency, and reliability of data across entities. Here's an in-depth look at the different types of constraints and mechanisms to enforce data integrity:

### 5.1. **Primary Key Constraints**

   - **UUID Primary Keys**: Each entity in the model, such as `User`, `Application`, `LeadProvider`, `Course`, etc., has a unique identifier (`uuid id`) as the primary key. This UUID ensures each record is uniquely identifiable, even if data spans multiple databases or systems.
   - **Natural Primary Keys**: Certain entities have natural unique identifiers (e.g., `email` in `User`, `urn` in `School`). While these fields aren't necessarily primary keys, they add another layer of uniqueness.

### 5.2. **Foreign Key Constraints**

   - **Relationships and Integrity**: Foreign keys link entities and enforce referential integrity:
     - For example, `Application` references `User`, `LeadProvider`, `Course`, `Schedule`, and optional entities like `School`, `PrivateChildcareProvider`, and `IttProvider`. Foreign keys ensure that an `Application` cannot exist without a valid associated `User`, `LeadProvider`, etc.
   - **Optional Foreign Keys**: Some relationships are optional (like those linking `Application` to `School` or `PrivateChildcareProvider`). In these cases, the foreign key can be null, allowing flexibility without breaking referential integrity.

### 5.3. **Unique Constraints**

   - **Entity-Level Uniqueness**: Unique constraints prevent duplicate entries where they don't make sense:
     - `User.email` is likely constrained to be unique, ensuring each user has a distinct email address.
     - `LeadProvider.name` and `Course.identifier` may also be unique to prevent duplicating providers or courses.
   - **Composite Uniqueness**: For multi-field uniqueness, composite keys might apply, though they aren't explicitly shown here. For instance:
     - A composite key on `Statement` might include `month`, `year`, and `lead_provider_id` to ensure only one statement per month and year per lead provider.

### 5.4. **NOT NULL Constraints**

   - **Mandatory Fields**: Many fields are non-nullable (e.g., `User.email`, `LeadProvider.name`, `Application.course_id`). This constraint ensures all mandatory information is provided:
     - For example, `Application` requires fields like `user_id`, `course_id`, and `lead_provider_id` for it to be complete and valid.
   - **Conditional Non-Null Fields**: Some fields may be required based on specific conditions. For instance, if `Application.works_in_school` is true, then `school_id` might be required.

### 5.5. **Data Type Constraints**

   - **Correct Data Types**: Enforcing appropriate data types (e.g., `string`, `boolean`, `date`, `datetime`, `decimal`, `integer`) is essential:
     - Dates such as `declaration_date` in `Declaration` or `completion_date` in `ParticipantOutcome` ensure only valid dates are entered.
     - `decimal` fields in `ContractTemplate` allow precision for fields like `service_fee_percentage`.
   - **Enumerations and Booleans**: Fields like `Statement.month` (an enum representing months) or boolean fields such as `Application.eligible_for_funding` restrict entries to valid choices, enhancing consistency.

### 5.6. **Default Values**

   - **Default States and Flags**: Some fields may have default values to ensure consistent initial states:
     - For example, `Application.lead_provider_approval_status` could default to "pending" until reviewed.
   - **Automatic Timestamps**: `datetime` fields like `updated_at` and `created_at` across various entities are often automatically set to the current timestamp upon record creation or update, ensuring accurate logging.

### 5.7. **Business Rules and Domain-Specific Constraints**

   - **Financial and Contractual Rules**: Business rules ensure accurate financial processing:
     - `ContractTemplate.number_of_payment_periods` and `per_participant` must be set according to agreed terms to enforce compliance in budgeting and payment schedules.
   - **Eligibility and Funding**: Constraints related to funding eligibility (`Application.eligible_for_funding`, `Application.funding_choice`) require specific conditions to be met. For instance, only certain roles might be eligible for funding, and specific eligibility criteria need to be met based on `teacher_catchment_country`.

### 5.8. **Cascade Rules and Referential Actions**

   - **ON DELETE and ON UPDATE**: Referential actions like `ON DELETE CASCADE` or `ON DELETE SET NULL` are used for dependent records:
     - If a `LeadProvider` is deleted, associated `Application` records might also be deleted (cascade delete) to maintain referential integrity.
     - `ON UPDATE CASCADE` ensures that if a referenced record changes (e.g., `Course.id`), all related `Application` records are automatically updated.

### 5.9. **Validation and Consistency Constraints**

   - **Consistent State Transitions**: Fields representing states (e.g., `Declaration.state`, `Statement.state`, `ParticipantOutcome.state`) are likely validated against permissible transitions. For example:
     - A `Declaration` might only move from "submitted" to "approved," ensuring invalid states are not assigned.
   - **Date Validations**: Date fields like `Schedule.declaration_starts_on` and `declaration_starts_on` might be validated to ensure logical consistency (e.g., `schedule_applies_from` is before `schedule_applies_to`).

### 5.10. **Application-Specific Constraints**

   - **Application Fields**: Some fields in `Application` capture specific criteria (e.g., `headteacher_status`, `training_status`). Constraints on these fields can ensure only valid statuses (e.g., active, inactive) are allowed, which impacts eligibility and training reporting.
   - **Outcome Associations**: `ParticipantOutcome.declaration_id` must link to an existing declaration, and constraints may enforce that an outcome cannot exist without a completed declaration.

#### Summary of Data Integrity Focus

1. **Entity Uniqueness and Referencing**: Each record is uniquely identifiable, with strong foreign key constraints for relationships.
2. **Validation of Data Types**: Correct data types ensure data accuracy, and enums/booleans enforce valid value choices.
3. **Mandatory Fields and Domain-Specific Rules**: Non-nullable and conditional fields enforce that all essential data is recorded accurately.
4. **Cascade Rules**: Referential actions maintain data consistency during deletions or updates.


## 6. Notes

* Document on `NPQ Contract` can be found [here](npq_contracts.md).
