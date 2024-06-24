# What you can do in the API

<div class="govuk-inset-text">
The focus of the following guidance is on business logic only. Critical details which would be necessary for real-world usage have been left out. For example, authentication is not detailed.
</div>

## NPQ processes

Before delving into the specifics of API requests, here's an overview of how NPQs work.

### Applications

1. A person submits an application for a course using the [Register for a national professional qualification](https://register-national-professional-qualifications.education.gov.uk/) service.
2. Providers view NPQ application data via the API.
3. Providers complete their own suitability and application processes.
4. Providers accept or reject applications via the API and onboarding participants onto their systems. 

### Training starts

1. Providers train participants as per details set out in the contract.
2. Providers submit started declarations via the API to notify DfE that participants have started their courses.
3. DfE pays providers output payments for started declarations.

### Training continues

1. Providers continue to train participants as per details set out in the contract.
2. Providers submit retained declarations via the API to notify DfE participants have continued in training for a given milestone.
3. DfE pays providers output payments for retained declarations.

### After the participant has completed their NPQ

1. Providers complete training participants as per details set out in the contract.
2. Providers will submit completed declarations via the API, including participant outcomes, to notify DfE participants have completed the course.
3. DfE will pay providers output payments for completed declarations. 

### Other things to consider: 

* providers can view financial statements via the API
* changes can happen during training. Some participants may not complete their course within the standard schedule, or at all. Providers must update relevant data using the API
* DfE will only make payments for participants if providers have accepted course applications. Accepting applications is a separate request to submitting a ‘started’ declaration (which notifies DfE a participant has started training)
