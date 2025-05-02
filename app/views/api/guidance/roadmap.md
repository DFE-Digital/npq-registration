# Roadmap

## Why we’re sharing our roadmap publicly

This document explains what we’re working on to improve the digital services that facilitate the national professional qualification (NPQ) service.

It sets out what we’re working on now, what will come next, and what we might pursue later.

By sending this out publicly, we hope to:

- give direction to lead providers
- be transparent about what we’re working on and why
- gather more feedback about the work we’re aiming to do

Our objectives are centered around how we can make it easier for applicants to register for NPQs, and lead providers to process NPQ applicants.

<div class="govuk-grid-row">

<div class="govuk-grid-column-one-third">
<h2 id="now" class="govuk-heading-m">Now 🏃</h2>
<p class="govuk-body-m">We are:</p>
<strong> Improving the user journey </strong>
<ul class="govuk-list govuk-list--bullet">
<li>Changing up the applicant journey to better accommodate overseas and self-funded applicants.</li>
<li>BAU improvements to the service.</li>
</ul>
<strong> Delivery Partner / Declaration API changes </strong>
<ul class="govuk-list govuk-list--bullet">
<li>For 2024 cohort declarations or later, you must provide a Delivery Partner ID.</li>
<li>The exception is for Overseas applicants, where you must not include a Delivery Partner ID.</li>
</ul>
<strong> Other technical changes to optimise the service </strong>
<ul class="govuk-list govuk-list--bullet">
<li>Restricting access to API based on IP range (to be commissioned).</li>
<li>Drop the maximum page size to 1000 for API requests.</li>
</ul>
</div>

<div class="govuk-grid-column-one-third">
<h2 id="next" class="govuk-heading-m">Next ➡️</h2>
<p class="govuk-body-m">We will:</p>
<strong>Identifying records more easily</strong>
<ul class="govuk-list govuk-list--bullet">
<li>Include the Application ID within the API response body for the Participant Declarations endpoint.</li>
<li>Show SENCO specific fields within API response for Application endpoints.</li>
</ul>
<strong>Processing applications more efficiently</strong>
<ul class="govuk-list govuk-list--bullet">
<li>Ability to reject a previously accepted application (with no declarations).</li>
<li>Ability to change the application cohort for funded places, to allow applicants to register.</li>
<li>Ability to have visibility of declarations if applicant was transferred.</li>
<li>Ability to see why an application was rejected, including if another provider has accepted or the DfE has rejected the application.</li>
</ul>
</div>

<div class="govuk-grid-column-one-third">
<h2 id="later" class="govuk-heading-m">Later 🔮</h2>
<p class="govuk-body-m">We will:</p>
<strong>Technical debt</strong>
<ul class="govuk-list govuk-list--bullet">
<li>Deprecating v1 and v2 of the API, now that everyone has migrated to v3, post-separation.</li>
</ul>
</div>

</div>
