# Participant training journey diagrams

These diagrams give an overview of the processes that take place during the different phases of an NPQ participant's training journey. We'll iterate these based on feedback from providers and DfE support staff.   

## Course preparation 

<div class="mermaid">
    sequenceDiagram
    participant teacher as Participant
    participant provider as Provider

    Note over teacher: Find out course info 
    provider->>+teacher: Send start date, in-person session timings etc.
    provider->>+teacher: Send participant training platform login details
    Note over teacher: Access training platforms

</div>

## Course introduction

<div class="mermaid">
    sequenceDiagram
    participant teacher as Participant
    participant provider as Provider

    Note over teacher: Attend intro session
    teacher->>+provider: This is often referred to as a ‘conference’ 
    Note over provider: Run intro session

</div>

## Start of course

<div class="mermaid">
    sequenceDiagram
    participant teacher as Participant
    participant provider as Provider
    participant endpoint as API endpoint
    participant dfe as DfE

    Note over teacher: Start course
    Note over provider: Submit 'Start' declaration
    provider->>+endpoint: 
    Note over endpoint: Declare a participant has reached a milestone
    endpoint->>+dfe: 
    Note over dfe: Calculate payment due for ‘Start’ declarations 

</div>

## Updating participant info in the API during the course 

<div class="mermaid">
    sequenceDiagram
    participant teacher as Participant
    participant provider as Provider
    participant endpoint as API endpoint
    participant dfe as DfE
  
    Note over provider: Run course
    provider->>+teacher:  
    Note over teacher: Attend training sessions
    teacher->>+provider:  
    Note over provider: Document attendance 
    Note over provider: Gather assurance evidence
    provider->>+endpoint: Submit declarations at each milestone
    Note over endpoint: Declare a participant has reached a milestone
    endpoint->>+dfe:  
    Note over dfe: Check declarations
    Note over dfe: Update financial statements
    dfe->>+endpoint: 
    Note over endpoint: Retrieve financial statements
    endpoint->>provider:  
    Note over provider: Check financial statements
       
</div>

## Payments process 

<div class="mermaid">
    sequenceDiagram
    participant provider as Provider
    participant dfe as DfE
    
    provider->>+dfe: Send invoices to DfE
    Note over dfe: Check invoices
    dfe->>+provider: Send participant output fee at each milestone
    Note over provider: Receive output fees  
    dfe->>+provider: Send service fee monthly for target number of participants
    Note over provider: Receive service fees
    
</div>