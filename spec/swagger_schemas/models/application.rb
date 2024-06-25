APPLICATION = {
  v1: {
    description: "A single NPQ application",
    type: :object,
    required: %i[id type attributes],
    properties: {
      id: {
        "$ref": "#/components/schemas/IDAttribute",
      },
      type: {
        description: "The data type",
        type: :string,
        enum: %w[
          npq_application
        ],
      },
      attributes: {
        properties: {
          course_identifier: {
            description: "The NPQ course this NPQ application relates to",
            type: :string,
            nullable: false,
            enum: %w[
              npq-leading-teaching
              npq-leading-behaviour-culture
              npq-leading-teaching-development
              npq-leading-literacy
              npq-senior-leadership
              npq-headship
              npq-executive-leadership
              npq-early-years-leadership
              npq-additional-support-offer
              npq-early-headship-coaching-offer
              npq-leading-primary-mathematics
              npq-senco
            ],
          },
          email: {
            description: "The email address registered for this NPQ participant",
            type: :string,
            nullable: false,
          },
          email_validated: {
            description: "Indicates whether the email address has been validated",
            type: :boolean,
          },
          employer_name: {
            description: "The name of current employer of the participant if not currently employed by school",
            type: :string,
            nullable: true,
          },
          employment_role: {
            description: "Participant's current role in the company they are employed in if not currently employed by school",
            type: :string,
            nullable: true,
          },
          full_name: {
            description: "The full name of this NPQ participant",
            type: :string,
            nullable: false,
          },
          funding_choice: {
            description: "Indicates how this NPQ participant has said they will funded their training",
            type: :string,
            nullable: true,
            enum: %w[
              school
              trust
              self
              another
              employer
            ],
          },
          headteacher_status: {
            description: "Indicates whether this NPQ participant is or will be a head teacher",
            type: :string,
            enum: %w[
              no
              yes_when_course_starts
              yes_in_first_two_years
              yes_over_two_years
              yes_in_first_five_years
              yes_over_five_years
            ],
          },
          ineligible_for_funding_reason: {
            description: "Indicates why this NPQ participant is not eligible for DfE funding",
            type: :string,
            nullable: true,
            enum: %w[
              establishment-ineligible
              previously-funded
            ],
          },
          participant_id: {
            description: "The unique identifier of this NPQ participant",
            type: :string,
            format: "uuid",
          },
          private_childcare_provider_urn: {
            description: "The Unique Reference Number (URN) of the private child care provider",
            type: :string,
            nullable: true,
          },
          teacher_reference_number: {
            description: "The Teacher Reference Number (TRN) for this NPQ participant",
            type: :string,
          },
          teacher_reference_number_validated: {
            description: "Indicates whether the Teacher Reference Number (TRN) has been validated",
            type: :boolean,
            nullable: false,
          },
          school_urn: {
            description: "The Unique Reference Number (URN) of the school where this NPQ participant is employed",
            type: :string,
          },
          school_ukprn: {
            description: "The UK Provider Reference Number (UK Provider Reference Number) of the school where this NPQ participant is employed",
            nullable: true,
            type: :string,
          },
          status: {
            description: "The current state of the NPQ application",
            type: :string,
            nullable: true,
            enum: %w[
              pending
              accepted
              rejected
            ],
          },
          works_in_school: {
            description: "Indicates whether the participant is currently employed by school",
            type: :boolean,
          },
          created_at: {
            description: "The date the application was created",
            type: :string,
            nullable: false,
            format: :"date-time",
          },
          updated_at: {
            description: "The date the application was last updated",
            type: :string,
            nullable: false,
            format: :"date-time",
          },
          cohort: {
            description: "Indicates which call-off contract would fund this participant's training. 2021 indicates a participant that has started, or will start, their training in the 2021/22 academic year. Once a provider accepts an application, they may change a participant's cohort up until the point of submitting a started declaration.",
            type: :string,
            nullable: true,
          },
          eligible_for_funding: {
            description: "Indicates whether this NPQ participant would be eligible for funding from the DfE",
            type: :boolean,
          },
          targeted_delivery_funding_eligibility: {
            description: "Whether or not this application is eligible for Targeted Delivery Funding uplift",
            nullable: false,
            type: :boolean,
          },
          teacher_catchment: {
            description: "This field will indicate whether or not the participant is UK-based. <ul><li>If <code>true</code> then the registration relates to a participant who is UK-based.</li><li>If <code>false</code> then the registration relates to a participant who is not UK-based.</li></ul>",
            nullable: true,
            type: :boolean,
          },
          teacher_catchment_country: {
            description: "This field shows the text entered by the participant during their NPQ online registration.",
            nullable: true,
            type: :string,
          },
          teacher_catchment_iso_country_code: {
            description: "This field identifies which non-UK country the participant has registered from.\nThe API uses <a href=\"https://www.iso.org/iso-3166-country-codes.html\" class=\"govuk-link\" rel=\"noreferrer noopener\" target=\"_blank\">ISO 3166 alpha-3 codes</a>, three-letter codes published by the International Organization for Standardization (ISO) to represent countries, dependent territories, and special areas of geographical interest.",
            nullable: true,
            type: :string,
          },
          itt_provider: {
            description: "This field contains the legal name of the ITT accredited provider from the <a href=\"https://www.gov.uk/government/publications/accredited-initial-teacher-training-itt-providers/list-of-providers-accredited-to-deliver-itt-from-september-2024\" class=\"govuk-link\" rel=\"noreferrer noopener\" target=\"_blank\">list of providers</a>.",
            nullable: true,
            type: :string,
          },
          lead_mentor: {
            description: "This field indicates whether the applicant is an ITT lead mentor.",
            nullable: true,
            type: :boolean,
          },
          funded_place: {
            description: "This field indicates whether the application is funded",
            nullable: true,
            type: :boolean,
          },
        },
      },
    },
  },
}.tap { |h|
  h[:v2] = h[:v1]
  h[:v3] = {
    description: "A single NPQ application",
    type: :object,
    required: %i[id type attributes],
    properties: {
      id: {
        "$ref": "#/components/schemas/IDAttribute",
      },
      type: {
        description: "The data type",
        type: :string,
        enum: %w[
          npq_application
        ],
      },
      attributes: {
        properties: {
          participant_id: {
            description: "The unique identifier of this NPQ participant",
            type: :string,
            nullable: false,
            format: "uuid",
          },
          full_name: {
            description: "The full name of this NPQ participant",
            type: :string,
            nullable: false,
          },
          email: {
            description: "The email address registered for this NPQ participant",
            type: :string,
            nullable: false,
          },
          email_validated: {
            description: "Indicates whether the email address has been validated",
            type: :boolean,
          },
          teacher_reference_number: {
            description: "The Teacher Reference Number (TRN) for this NPQ participant",
            type: :string,
          },
          teacher_reference_number_validated: {
            description: "Indicates whether the Teacher Reference Number (TRN) has been validated",
            type: :boolean,
            nullable: false,
          },
          works_in_school: {
            description: "Indicates whether the participant is currently employed by school",
            type: :boolean,
          },
          employer_name: {
            description: "The name of current employer of the participant if not currently employed by school",
            type: :string,
            nullable: true,
          },
          employment_role: {
            description: "Participant's current role in the company they are employed in if not currently employed by school",
            type: :string,
            nullable: true,
          },
          school_urn: {
            description: "The Unique Reference Number (URN) of the school where this NPQ participant is employed",
            type: :string,
          },
          private_childcare_provider_urn: {
            description: "The Unique Reference Number (URN) of the private child care provider",
            type: :string,
            nullable: true,
          },
          school_ukprn: {
            description: "The UK Provider Reference Number (UK Provider Reference Number) of the school where this NPQ participant is employed",
            nullable: true,
            type: :string,
          },
          headteacher_status: {
            description: "Indicates whether this NPQ participant is or will be a head teacher",
            type: :string,
            enum: %w[
              no
              yes_when_course_starts
              yes_in_first_two_years
              yes_over_two_years
              yes_in_first_five_years
              yes_over_five_years
            ],
          },
          eligible_for_funding: {
            description: "Indicates whether this NPQ participant would be eligible for funding from the DfE",
            type: :boolean,
          },
          funding_choice: {
            description: "Indicates how this NPQ participant has said they will funded their training",
            type: :string,
            nullable: true,
            enum: %w[
              school
              trust
              self
              another
              employer
            ],
          },
          course_identifier: {
            description: "The NPQ course this NPQ application relates to",
            type: :string,
            nullable: false,
            enum: %w[
              npq-leading-teaching
              npq-leading-behaviour-culture
              npq-leading-teaching-development
              npq-leading-literacy
              npq-senior-leadership
              npq-headship
              npq-executive-leadership
              npq-early-years-leadership
              npq-additional-support-offer
              npq-early-headship-coaching-offer
              npq-leading-primary-mathematics
              npq-senco
            ],
          },
          status: {
            description: "The current state of the NPQ application",
            type: :string,
            nullable: true,
            enum: %w[
              pending
              accepted
              rejected
            ],
          },
          created_at: {
            description: "The date the application was created",
            type: :string,
            nullable: false,
            format: :"date-time",
          },
          updated_at: {
            description: "The date the application was last updated",
            type: :string,
            nullable: false,
            format: :"date-time",
          },
          ineligible_for_funding_reason: {
            description: "Indicates why this NPQ participant is not eligible for DfE funding",
            type: :string,
            nullable: true,
            enum: %w[
              establishment-ineligible
              previously-funded
            ],
          },
          cohort: {
            description: "Indicates which call-off contract would fund this participant's training. 2021 indicates a participant that has started, or will start, their training in the 2021/22 academic year. Once a provider accepts an application, they may change a participant's cohort up until the point of submitting a started declaration.",
            type: :string,
            nullable: true,
          },
          targeted_delivery_funding_eligibility: {
            description: "Whether or not this application is eligible for Targeted Delivery Funding uplift",
            nullable: false,
            type: :boolean,
          },
          teacher_catchment: {
            description: "This field will indicate whether or not the participant is UK-based. <ul><li>If <code>true</code> then the registration relates to a participant who is UK-based.</li><li>If <code>false</code> then the registration relates to a participant who is not UK-based.</li></ul>",
            nullable: true,
            type: :boolean,
          },
          teacher_catchment_country: {
            nullable: true,
            type: :string,
          },
          teacher_catchment_iso_country_code: {
            description: "This field identifies which non-UK country the participant has registered from.\nThe API uses <a href=\"https://www.iso.org/iso-3166-country-codes.html\" class=\"govuk-link\" rel=\"noreferrer noopener\" target=\"_blank\">ISO 3166 alpha-3 codes</a>, three-letter codes published by the International Organization for Standardization (ISO) to represent countries, dependent territories, and special areas of geographical interest.",
            nullable: true,
            type: :string,
          },
          lead_mentor: {
            description: "This field indicates whether the applicant is an ITT lead mentor.",
            nullable: true,
            type: :boolean,
          },
          itt_provider: {
            description: "This field contains the legal name of the ITT accredited provider from the <a href=\"https://www.gov.uk/government/publications/accredited-initial-teacher-training-itt-providers/list-of-providers-accredited-to-deliver-itt-from-september-2024\" class=\"govuk-link\" rel=\"noreferrer noopener\" target=\"_blank\">list of providers</a>.",
            nullable: true,
            type: :string,
          },
          schedule_identifier: {
            description: "The new schedule of the participant",
            nullable: true,
            type: :string,
            enum: %w[
              npq-aso-march
              npq-aso-june
              npq-aso-november
              npq-aso-december
              npq-ehco-march
              npq-ehco-june
              npq-ehco-november
              npq-ehco-december
              npq-leadership-autumn
              npq-leadership-spring
              npq-specialist-autumn
              npq-specialist-spring
            ],
          },
          funded_place: {
            description: "This field indicates whether the application is funded",
            nullable: true,
            type: :boolean,
          },
        },
      },
    },
  }
}.freeze
