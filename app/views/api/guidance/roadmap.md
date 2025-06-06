# Roadmap

This page explains what we’re working on to improve the digital services that facilitate the national professional qualification (NPQ) service.

It sets out what we’re working on now, what will come next, and what we might pursue later.

By sharing this publicly, we hope to:

- give direction to lead providers
- be transparent about what we’re working on and why
- gather more feedback about the work we’re aiming to do

Our objectives are centered around how we can make it easier for applicants to register for NPQs, and make it more efficient for lead providers to process NPQ applicants.

<div class="govuk-grid-row">

<div class="govuk-grid-column-one-third">
  <h2 id="now" class="govuk-heading-m">Now</h2>
  <p class="govuk-body-m">We are:</p>
  <p class="govuk-body-m"><strong>Improving the user journey</strong></p>
  <ul class="govuk-list govuk-list--bullet">
    <li>Understanding how we can adapt the service to better accommodate overseas and self-funded applicants in the future.</li>
    <li>Maintaining and making general day-to-day improvements to the registration service.</li>
  </ul>
  <p class="govuk-body-m"><strong>Giving providers the ability to indicate the Delivery Partner with API Declarations</strong></p>
  <ul class="govuk-list govuk-list--bullet">
    <li>For 2024 cohort declarations or later, the Delivery Partner ID must be provided.</li>
    <li>The exception is for Overseas applicants, where you must not include a Delivery Partner ID.</li>
  </ul>
</div>

  <div class="govuk-grid-column-one-third">
    <h2 id="next" class="govuk-heading-m">Next</h2>
    <p class="govuk-body-m">We will:</p>
    <p class="govuk-body-m"><strong>Help providers identify records more easily</strong></p>
      <ul class="govuk-list govuk-list--bullet">
        <li>Include the Application ID within the API response body for the Participant Declarations endpoint.</li>
        <li>Show SENCO specific fields within the API response for Application endpoints.</li>
        <li>Ability to see why an application was rejected, including if another provider has accepted or the DfE has rejected the application.</li>
        <li>Ability to have visibility of declarations if an applicant was transferred.</li>
      </ul>
    <p class="govuk-body-m"><strong>Make other technical changes to optimise the service</strong></p>
      <ul class="govuk-list govuk-list--bullet">
        <li>Restrict access to the API based on the provider's IP range (to be commissioned).</li>
        <li>Drop the maximum page size to 1000 for API requests.</li>
      </ul>
    <p class="govuk-body-m"><strong>Process applications more efficiently</strong></p>
      <ul class="govuk-list govuk-list--bullet">
        <li>Ability to reject a previously accepted application with no declarations.</li>
        <li>Explore the ability to change the application cohort for funded places, to allow applicants to register.</li>
      </ul>
  </div>

  <div class="govuk-grid-column-one-third">
    <h2 id="later" class="govuk-heading-m">Later</h2>
    <p class="govuk-body-m">We plan to:</p>
    <p class="govuk-body-m"><strong>Technical debt</strong></p>
      <ul class="govuk-list govuk-list--bullet">
        <li>Deprecate the legacy versions of the API (v1 & v2), now that providers have migrated to v3 since separating from ECF.</li>
      </ul>
  </div>

</div>
