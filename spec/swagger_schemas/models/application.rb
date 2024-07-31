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
        example: "npq_application",
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
            example: Course::IDENTIFIERS.first,
            enum: Course::IDENTIFIERS,
          },
          email: {
            description: "The email address registered for this NPQ participant",
            type: :string,
            nullable: false,
            example: "isabelle.macdonald2@some-school.example.com",
          },
          email_validated: {
            description: "Indicates whether the email address has been validated",
            type: :boolean,
            example: true,
          },
          employer_name: {
            description: "The name of current employer of the participant if not currently employed by school",
            type: :string,
            nullable: true,
            example: "Some Company Ltd",
          },
          employment_role: {
            description: "Participant's current role in the company they are employed in if not currently employed by school",
            type: :string,
            nullable: true,
            example: "Director",
          },
          full_name: {
            description: "The full name of this NPQ participant",
            type: :string,
            nullable: false,
            example: "Isabelle MacDonald",
          },
          funding_choice: {
            description: "Indicates how this NPQ participant has said they will funded their training",
            type: :string,
            nullable: true,
            example: Application.funding_choices.keys.first,
            enum: Application.funding_choices.keys,
          },
          headteacher_status: {
            description: "Indicates whether this NPQ participant is or will be a head teacher",
            type: :string,
            example: Application.headteacher_statuses.keys.first,
            enum: Application.headteacher_statuses.keys,
          },
          ineligible_for_funding_reason: {
            description: "Indicates why this NPQ participant is not eligible for DfE funding",
            type: :string,
            nullable: true,
            example: Application::INELIGIBLE_FOR_FUNDING_REASONS.first,
            enum: Application::INELIGIBLE_FOR_FUNDING_REASONS,
          },
          participant_id: {
            description: "The unique identifier of this NPQ participant",
            type: :string,
            example: "7a8fef46-3c43-42c0-b3d5-1ba5904ba562",
            format: "uuid",
          },
          private_childcare_provider_urn: {
            description: "The Unique Reference Number (URN) of the private child care provider",
            type: :string,
            example: "EY944860",
            nullable: true,
          },
          teacher_reference_number: {
            description: "The Teacher Reference Number (TRN) for this NPQ participant",
            type: :string,
            example: "1234567",
          },
          teacher_reference_number_validated: {
            description: "Indicates whether the Teacher Reference Number (TRN) has been validated",
            type: :boolean,
            nullable: false,
            example: true,
          },
          school_urn: {
            description: "The Unique Reference Number (URN) of the school where this NPQ participant is employed",
            type: :string,
            example: "106286",
          },
          school_ukprn: {
            description: "The UK Provider Reference Number (UK Provider Reference Number) of the school where this NPQ participant is employed",
            nullable: true,
            type: :string,
            example: "10079319",
          },
          status: {
            description: "The current state of the NPQ application",
            type: :string,
            nullable: true,
            example: Application.lead_provider_approval_statuses.keys.first,
            enum: Application.lead_provider_approval_statuses.keys,
          },
          works_in_school: {
            description: "Indicates whether the participant is currently employed by school",
            type: :boolean,
            example: true,
          },
          cohort: {
            description: "Indicates which call-off contract would fund this participant's training. 2021 indicates a participant that has started, or will start, their training in the 2021/22 academic year. Once a provider accepts an application, they may change a participant's cohort up until the point of submitting a started declaration.",
            type: :string,
            nullable: true,
            example: "2022",
          },
          eligible_for_funding: {
            description: "Indicates whether this NPQ participant would be eligible for funding from the DfE",
            type: :boolean,
            example: true,
          },
          targeted_delivery_funding_eligibility: {
            description: "Whether or not this application is eligible for Targeted Delivery Funding uplift",
            nullable: false,
            type: :boolean,
            example: true,
          },
          teacher_catchment: {
            description: "This field will indicate whether or not the participant is UK-based. <ul><li>If <code>true</code> then the registration relates to a participant who is UK-based.</li><li>If <code>false</code> then the registration relates to a participant who is not UK-based.</li></ul>",
            nullable: true,
            type: :boolean,
            example: true,
          },
          teacher_catchment_country: {
            description: "This field shows the text entered by the participant during their NPQ online registration.",
            nullable: true,
            type: :string,
            example: "United Kingdom of Great Britain and Northern Ireland",
          },
          teacher_catchment_iso_country_code: {
            description: "This field identifies which non-UK country the participant has registered from.\nThe API uses <a href=\"https://www.iso.org/iso-3166-country-codes.html\" class=\"govuk-link\" rel=\"noreferrer noopener\" target=\"_blank\">ISO 3166 alpha-3 codes</a>, three-letter codes published by the International Organization for Standardization (ISO) to represent countries, dependent territories, and special areas of geographical interest.",
            nullable: true,
            type: :string,
            example: "GBR",
          },
          itt_provider: {
            description: "This field contains the legal name of the ITT accredited provider from the <a href=\"https://www.gov.uk/government/publications/accredited-initial-teacher-training-itt-providers/list-of-providers-accredited-to-deliver-itt-from-september-2024\" class=\"govuk-link\" rel=\"noreferrer noopener\" target=\"_blank\">list of providers</a>.",
            nullable: true,
            type: :string,
            example: "University of Southampton",
          },
          lead_mentor: {
            description: "This field indicates whether the applicant is an ITT lead mentor.",
            nullable: true,
            type: :boolean,
            example: true,
          },
          funded_place: {
            description: "Indicates whether or not this participant’s training is being funded by DfE",
            nullable: true,
            type: :boolean,
            example: nil,
          },
          created_at: {
            description: "The date the application was created",
            type: :string,
            nullable: false,
            format: :"date-time",
            example: "2021-05-31T02:21:32.000Z",
          },
          updated_at: {
            description: "The date the application was last updated",
            type: :string,
            nullable: false,
            format: :"date-time",
            example: "2021-05-31T02:22:32.000Z",
          },
        },
      },
    },
  },
}.tap { |h|
  h[:v2] = h[:v1].deep_dup
  h[:v3] = h[:v2].deep_dup
  h[:v3][:properties][:attributes][:properties][:schedule_identifier] = {
    description: "The new schedule of the participant",
    nullable: true,
    type: :string,
    example: Schedule::IDENTIFIERS.first,
    enum: Schedule::IDENTIFIERS,
  }
}.freeze
