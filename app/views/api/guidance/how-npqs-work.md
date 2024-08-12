# How NPQs work  

## The application stage

1. Once someone has registered with us to do an NPQ, providers can view their application data via our API.   
2. Providers complete their own suitability and application processes.
3. Providers process applications via our API. This is where providers can confirm whether or not training will be DfE-funded.
4. Process set successful applicants up on their training portals. 

## Training starts

1. Providers train participants as per details set out in the contract.
2. Providers submit started declarations via the API to notify DfE that participants have started their courses.
3. DfE pays providers output payments for started declarations.

## Training continues

1. Providers continue to train participants as per details set out in the contract.
2. Providers submit retained declarations via the API to notify DfE participants have continued in training for a given milestone.
3. DfE pays providers output payments for retained declarations.

## After the participant has completed their NPQ

1. Providers complete training participants as per details set out in the contract.
2. Providers will submit completed declarations via the API, including participant outcomes, to notify DfE participants have completed the course.
3. DfE will pay providers output payments for completed declarations. 

## Other considerations 

It's worth noting that:

* providers can view financial statements via the API
* changes can happen during training. Some participants may not complete their course within the standard schedule, or at all. Providers must update relevant data using the API
* DfE will only make payments for participants if providers have accepted course applications. Accepting applications is a separate request to submitting a ‘started’ declaration (which notifies DfE a participant has started training)