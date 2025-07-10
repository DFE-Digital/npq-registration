# Roadmap

This roadmap shows how we’re improving the digital services that support the national professional qualification (NPQ) programme.

It shows what:

- we’re working on now
- we plan to work on next
- we might work on in the future

We’re sharing this to:

- help lead providers understand our direction
- be open about our work and the reasons behind it
- get feedback to help shape what we do next

### Our goals

We want to:

- make it easier for applicants to register for NPQs
- help lead providers manage applications more efficiently

<br>

<div class="govuk-grid-row">

  <div class="govuk-grid-column-one-third">
    <h2 id="now" class="govuk-heading-m">Now</h2>
    <p class="govuk-body-m"><strong>Improving the user journey</strong></p>
        <p class="govuk-body-m">We are:</p>
    <ul class="govuk-list govuk-list--bullet">
      <li>adapting the service to  accommodate overseas and self-funded applicants in the future</li>
      <li>making general day-to-day improvements to the registration service</li>
    </ul>
    <p class="govuk-body-m"><strong>Let providers specify their delivery partner when making declarations through the API</strong></p>
    <ul class="govuk-list govuk-list--bullet">
      <li>For 2024 cohort declarations or later, the Delivery Partner ID must be provided (except for overseas applicants).</li>
    </ul>
  </div>

  <div class="govuk-grid-column-one-third">
    <h2 id="next" class="govuk-heading-m">Next</h2>
    <p class="govuk-body-m"><strong>Help providers identify records easily</strong></p>
        <p class="govuk-body-m">We will:</p>
    <ul class="govuk-list govuk-list--bullet">
      <li>include the Application ID within the API response body for the Participant Declarations endpoint</li>
      <li>show special educational needs co-ordinator-specific fields within the API response for Application endpoints</li>
      <li>let providers see why an application was rejected, including if it was accepted by another provider or rejected by DfE</li>
      <li>show declarations for applicants who have been transferred</li>
    </ul>
    <p class="govuk-body-m"><strong>Make technical changes to optimise performance</strong></p>
    <ul class="govuk-list govuk-list--bullet">
      <li>Restrict access to the API based on the provider's IP range (to be commissioned).</li>
      <li>Drop the maximum page size to 1000 for API requests.</li>
    </ul>
    <p class="govuk-body-m"><strong>Process applications more efficiently</strong></p>
    <ul class="govuk-list govuk-list--bullet">
      <li>Allow providers to reject an accepted application if no declarations have been made.</li>
      <li>Explore changing the application cohort for funded places to allow applicants to register.</li>
    </ul>
  </div>

  <div class="govuk-grid-column-one-third">
    <h2 id="later" class="govuk-heading-m">Later</h2>
    <p class="govuk-body-m"><strong>Technical debt</strong></p>
        <p class="govuk-body-m">We plan to:</p>
    <ul class="govuk-list govuk-list--bullet">
      <li>remove support for legacy API versions (v1 and v2) now that all providers use v3 after separating from ECF</li>
    </ul>
  </div>

</div>
