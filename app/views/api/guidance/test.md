# Test Page

A test page to demonstrate a Mermaid process diagram:

<div class="mermaid">
sequenceDiagram
    participant teacher as Participant
    participant provider as Provider
    participant assessor as Assessor
    participant dfe as DfE
    participant tra as TRA

    Note over teacher,tra: Assessment completion and submission
    Note over teacher: #nbsp;Do course assessment#nbsp;
    teacher->>+provider: Submit assessment to provider
    Note over provider: #nbsp;Receive assessment#nbsp;
    provider->>+assessor: Send assessment to Tribal (third-party assessor)
    Note over teacher,tra: Assessment review
    Note over assessor: #nbsp;Review assessment#nbsp;
    assessor->>+provider: Send assessment result to provider
    Note over provider: #nbsp;Receive outcome from assessor#nbsp;
    Note over teacher,tra: Processing outcomes
    Note over provider: #nbsp;Inform delivery partners of outcome#nbsp;
    provider->>+dfe: Send completion declaration (pass/fail) to DfE via API
    Note over dfe: #nbsp;Check completion declaration#nbsp;
    Note over dfe: #nbsp;Update participant record#nbsp;
    dfe->>+tra: Send passed outcomes to the Teaching Regulation Agency (TRA)
    Note over tra: #nbsp;Process certificate#nbsp;
    tra->>+dfe: Send course outcome to participant with link for them to get their certificate
    Note over dfe: #nbsp;Add outcome to participant assessor#nbsp;
    dfe->>+teacher: Get NPQ certificate
    Note over teacher: #nbsp;NPQ course complete#nbsp;
</div>

Some more text around it
