# Provider processes: edge cases and pain points  

## Helping inform potential participants 

<div class="mermaid">
    sequenceDiagram
    participant provider as Provider role/task
    participant dfe as Potential issues

    Note over provider: Confirming course availability 
    provider->>+dfe: 
    Note over dfe: Provider doesn’t have availability
    Note over provider: Give applicants course details (timings etc.)
    provider->>+dfe: 
    Note over dfe: Participants don't have enough info
</div>  

## Participant registration with DfE

<div class="mermaid">
    sequenceDiagram
    participant provider as Provider role/task
    participant assessor as API endpoints
    participant dfe as Potential issues

    Note over provider: Tell applicants to register with DfE 
    provider->>+dfe: 
    Note over dfe: Applicants have TRN problems
    Note over provider: Get registration details through DfE API
    provider->>+assessor: 
    Note over assessor: Retrieve a single application
    provider->>+assessor: 
    Note over assessor: Retrieve multiple applications
    provider->>+dfe: 
    Note over dfe: Provider can't see registration details
</div>

## Applying with providers

<div class="mermaid">
    sequenceDiagram
    participant provider as Provider role/task
    participant assessor as API endpoints
    participant dfe as Potential issues

    Note over provider: Email application form to participant
    Note over provider: Check details have been recorded in CRM database 
    provider->>+dfe: 
    Note over dfe: Application details not recorded
    Note over provider: Add application to CRM 
    provider->>+dfe: 
    Note over dfe: Can't add application to CRM
    Note over provider: Match application and registration together 
    provider->>+dfe: 
    Note over dfe: Can't match application and registration
    Note over provider: Send form to sponsor or referee   
    Note over provider: Suitability and eligibility checks
    provider->>+dfe: 
    Note over dfe: Applicant not suitable or eligible for course
    provider->>+dfe: 
    Note over dfe: Applicant not eligible for funding
    Note over provider: Check application
    Note over provider: Send successful applicants training agreement
    Note over provider: Inform contract managers of exact recruitment numbers
    Note over provider: Update application status via API
    provider->>+assessor:  
    Note over assessor: Accept an application
    provider->>+assessor:  
    Note over assessor: Reject an application
    Note over provider: Change funded place value
    provider->>+assessor:  
    Note over assessor: Change funded place value of an NPQ application

</div>

## Getting participants ready to start

<div class="mermaid">
    sequenceDiagram
    participant provider as Provider role/task
    participant assessor as API endpoints
    participant dfe as Potential issues
     
    Note over provider: Send particiant training portal login details
    provider->>+dfe: 
    Note over dfe: Participant can't access training platform 
    Note over provider: Run intro session
    provider->>+dfe: 
    Note over dfe: Participant doesn't attend intro session
</div>

## Training starts

<div class="mermaid">
    sequenceDiagram
    participant provider as Provider role/task
    participant assessor as API endpoints
    participant dfe as Potential issues
     
    Note over provider: Submit ‘Start’ declaration via API
    provider->>+assessor: 
    Note over assessor: Declare a participant has reached a milestone
    provider->>+dfe: 
    Note over dfe: Declarations errors
</div>

## Delivering the course

<div class="mermaid">
    sequenceDiagram
    participant provider as Provider role/task
    participant assessor as API endpoints
    participant dfe as Potential issues
     
    Note over provider: Run course 
    Note over provider: Record participant attendance
    Note over provider: Gather assurance evidence
    Note over provider: Submit declarations at each milestone
    provider->>+assessor: 
    Note over assessor: Declare a participant has reached a milestone
    provider->>+dfe: 
    Note over dfe: Declarations errors
    provider->>+dfe: 
    Note over dfe: Late declarations
    Note over provider: Check financial statements
    provider->>+dfe: 
    Note over dfe: Financial statement incorrect
    Note over provider: Send invoices to DfE finance department  
    Note over provider: Receive output fees 
    Note over provider: Receive service fees 
</div>

## Changes during the course

<div class="mermaid">
    sequenceDiagram
    participant provider as Provider role/task
    participant assessor as API endpoints
    participant dfe as Potential issues
     
    Note over provider: Notify DfE of course withdrawal via API 
    provider->>+assessor: 
    Note over assessor: Withdraw a participant
    Note over provider: Notify DfE of course deferral DfE via API
    provider->>+assessor: 
    Note over assessor: Defer a participant
    Note over provider: Notify DfE of schedule change via API
    provider->>+assessor: 
    Note over assessor: Notify that a participant is changing training schedule
    Note over provider: Notify DfE of participant resuming course via API
    provider->>+assessor: 
    Note over assessor: Resume a participant
</div>

## Assessment review

<div class="mermaid">
    sequenceDiagram
    participant provider as Provider role/task
    participant assessor as API endpoints
    participant dfe as Potential issues

    Note over provider: Receive assessment
    Note over provider: Send assessment to Tribal (third-party assessor) 
</div>

## Processing outcomes

<div class="mermaid">
    sequenceDiagram
    participant provider as Provider role/task
    participant assessor as API endpoints
    participant dfe as Potential issues

    Note over provider: Receive outcome from Tribal
    Note over provider: Send completion declaration (pass/fail) to DfE via API 
    provider->>+assessor: 
    Note over assessor: Declare a participant has reached a milestone
    provider->>+dfe: 
    Note over dfe: Completed declaration error
    provider->>+assessor: 
    Note over assessor: Submit an outcome for a single participant
    provider->>+assessor: 
    Note over assessor: Retrieve multiple NPQ outcomes for a single participant
    provider->>+assessor: 
    Note over assessor: Retrieve multiple NPQ outcomes for all participants
</div>   