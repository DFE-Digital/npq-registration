# Release notes

If you have any questions or comments about these notes, contact DfE via Slack or email.

## 16 August 2024

We’ve launched a new standalone API for providers to view, submit and update NPQ-based training data.  

### Get started in the production and testing environments 

We’ve sent the bearer token for the NPQs API individually to providers. 

We serve NPQ data from an API using the following base URLs for our production environments: 

* <a href="https://register-national-professional-qualifications.education.gov.uk/api/v1/">NPQ API production environment, version 1</a>
* <a href="https://register-national-professional-qualifications.education.gov.uk/api/v2/">NPQ API production environment, version 2</a>
* <a href="https://register-national-professional-qualifications.education.gov.uk/api/v3/">NPQ API production environment, version 3</a>

Providers can access our test environments using the following URLs:  

* <a href="https://npq-registration-separation-web.teacherservices.cloud/api/v1">NPQ API test environment, version 1</a>
* <a href="https://npq-registration-separation-web.teacherservices.cloud/api/v2">NPQ API test environment, version 2</a>
* <a href="https://npq-registration-separation-web.teacherservices.cloud/api/v3">NPQ API test environment, version 3</a> 

We've also created ECF-only test environments for providers that offer both ECF and NPQ training to undertake regression testing:  

* <a href="https://sp.manage-training-for-early-career-teachers.education.gov.uk/api-reference/reference-v1.html">ECF API v1 test environment, version 1</a> 
* <a href="https://sp.manage-training-for-early-career-teachers.education.gov.uk/api-reference/reference-v2.html">ECF API v2 test environment, version 2</a>
* <a href="https://sp.manage-training-for-early-career-teachers.education.gov.uk/api-reference/reference-v3.html">ECF API v3 test environment, version 3</a>

### Standalone NPQ API endpoints  

<table class="govuk-table">
<caption class="govuk-table__caption govuk-table__caption--m">Applications</caption>
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">Request type</th>
      <th scope="col" class="govuk-table__header govuk-table__header">Endpoint</th>
      <th scope="col" class="govuk-table__header govuk-table__header">Description</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>GET</code></th>
      <td class="govuk-table__cell govuk-table__cell">/api/v3/npq-applications</td>
      <td class="govuk-table__cell govuk-table__cell">Retrieve multiple applications</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>GET</code></th>
      <td class="govuk-table__cell govuk-table__cell">/api/v3/npq-applications/{id}</td>
      <td class="govuk-table__cell govuk-table__cell">Retrieve a single application</td>
    </tr>
       <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>POST</code></th>
      <td class="govuk-table__cell govuk-table__cell">/api/v3/npq-applications/{id}/accept</td>
      <td class="govuk-table__cell govuk-table__cell">Accept an application</td>
    </tr>
           <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>POST</code></th>
      <td class="govuk-table__cell govuk-table__cell">/api/v3/npq-applications/{id}/reject</td>
      <td class="govuk-table__cell govuk-table__cell">Reject an application</td>
    </tr>
            <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>PUT</code></th>
      <td class="govuk-table__cell govuk-table__cell">/api/v3/npq-applications/{id}/change-funded-place</td>
      <td class="govuk-table__cell govuk-table__cell">Change funded place value of an application</td>
    </tr>
  </tbody>
</table>

<table class="govuk-table">
<caption class="govuk-table__caption govuk-table__caption--m">Participant declarations</caption>
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">Request type</th>
      <th scope="col" class="govuk-table__header govuk-table__header">Endpoint</th>
      <th scope="col" class="govuk-table__header govuk-table__header">Description</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>POST</code></th>
      <td class="govuk-table__cell govuk-table__cell">/api/v3/participant-declarations</td>
      <td class="govuk-table__cell govuk-table__cell">Retrieve multiple participant declarations</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>POST</code></th>
      <td class="govuk-table__cell govuk-table__cell">/api/v3/participant-declarations</td>
      <td class="govuk-table__cell govuk-table__cell">Declare a participant has reached a milestone  </td>
    </tr>
       <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>GET</code></th>
      <td class="govuk-table__cell govuk-table__cell">/api/v3/participant-declarations/{id}</td>
      <td class="govuk-table__cell govuk-table__cell">Retrieve a single participant’s declarations</td>
    </tr>
           <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>PUT</code></th>
      <td class="govuk-table__cell govuk-table__cell">/api/v3/participant-declarations/{id}/void</td>
      <td class="govuk-table__cell govuk-table__cell">Void a declaration</td>
    </tr>
  </tbody>
</table>

<table class="govuk-table">
<caption class="govuk-table__caption govuk-table__caption--m">Participant outcomes</caption>
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">Request type</th>
      <th scope="col" class="govuk-table__header govuk-table__header">Endpoint</th>
      <th scope="col" class="govuk-table__header govuk-table__header">Description</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>GET</code></th>
      <td class="govuk-table__cell govuk-table__cell">/api/v3/participants/npq/outcomes</td>
      <td class="govuk-table__cell govuk-table__cell">Retrieve multiple NPQ outcomes for all participants</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>GET</code></th>
      <td class="govuk-table__cell govuk-table__cell">/api/v3/participants/npq/{id}/outcomes</td>
      <td class="govuk-table__cell govuk-table__cell">Retrieve multiple NPQ outcomes for a single participant</td>
    </tr>
       <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>POST</code></th>
      <td class="govuk-table__cell govuk-table__cell">/api/v3/participants/npq/{id}/outcomes</td>
      <td class="govuk-table__cell govuk-table__cell">Submit an NPQ outcome for a single participant</td>
    </tr>
  </tbody>
</table>

<table class="govuk-table">
<caption class="govuk-table__caption govuk-table__caption--m">Participants</caption>
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">Request type</th>
      <th scope="col" class="govuk-table__header govuk-table__header">Endpoint</th>
      <th scope="col" class="govuk-table__header govuk-table__header">Description</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>GET</code></th>
      <td class="govuk-table__cell govuk-table__cell">/api/v3/participants/npq</td>
      <td class="govuk-table__cell govuk-table__cell">Retrieve multiple participants</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>GET</code></th>
      <td class="govuk-table__cell govuk-table__cell">/api/v3/participants/npq/{id}</td>
      <td class="govuk-table__cell govuk-table__cell">Retrieve a single participant</td>
    </tr>
       <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>PUT</code></th>
      <td class="govuk-table__cell govuk-table__cell">/api/v3/participants/npq/{id}/resume</td>
      <td class="govuk-table__cell govuk-table__cell">Resume a participant</td>
    </tr>
     <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>PUT</code></th>
      <td class="govuk-table__cell govuk-table__cell">/api/v3/participants/npq/{id}/defer</td>
      <td class="govuk-table__cell govuk-table__cell">Defer a participant</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>PUT</code></th>
      <td class="govuk-table__cell govuk-table__cell">/api/v3/participants/npq/{id}/withdraw</td>
      <td class="govuk-table__cell govuk-table__cell">Withdraw a participant</td>
    </tr>
       <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>PUT</code></th>
      <td class="govuk-table__cell govuk-table__cell">/api/v3/participants/npq/{id}/change-schedule</td>
      <td class="govuk-table__cell govuk-table__cell">Notify that a participant is changing training schedule</td>
    </tr>
  </tbody>
</table>

<table class="govuk-table">
<caption class="govuk-table__caption govuk-table__caption--m">Statements</caption>
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th scope="col" class="govuk-table__header">Request type</th>
      <th scope="col" class="govuk-table__header govuk-table__header">Endpoint</th>
      <th scope="col" class="govuk-table__header govuk-table__header">Description</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>GET</code></th>
      <td class="govuk-table__cell govuk-table__cell">/api/v3/statements</td>
      <td class="govuk-table__cell govuk-table__cell">Retrieve financial statements</td>
    </tr>
    <tr class="govuk-table__row">
      <th scope="row" class="govuk-table__header"><code>GET</code></th>
      <td class="govuk-table__cell govuk-table__cell">/api/v3/statements/{id}</td>
      <td class="govuk-table__cell govuk-table__cell">Retrieve a specific financial statement</td>
    </tr>
  </tbody>
</table>

### Seed data

We’ll be generating seed data which cover scenarios where users have:  

* one application 
* multiple applications 
* accepted applications 
* rejected applications  
 
### Provider tech support 

Contact us via the engagement and policy leads if you want to discuss your integration and technical plans in more detail. 

Our team are happy to host technical workshops with providers to ensure this integration runs smoothly. 