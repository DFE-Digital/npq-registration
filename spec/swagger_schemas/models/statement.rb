STATEMENT = {
  v3: {
    description: "A financial statement.",
    type: :object,
    required: %i[id type attributes],
    properties: {
      id: {
        "$ref": "#/components/schemas/IDAttribute",
      },
      type: {
        description: "The data type.",
        type: :string,
      },
      attributes: {
        properties: {
          month: {
            description: "The month which appears on the statement in the DfE portal.",
            type: :string,
            nullable: false,
          },
          year: {
            description: "The calendar year which appears on the statement in the dfe portal.",
            type: :string,
            nullable: false,
          },
          cohort: {
            description: "The cohort - 2021 or 2022 - which the statement funds.",
            type: :string,
            nullable: false,
          },
          cut_off_date: {
            description: "The milestone cut off or review point for the statement.",
            type: :string,
            nullable: false,
          },
          payment_date: {
            description: "The date we expect to pay you for any declarations attached to the statement, which are eligible for payment.",
            type: :string,
            nullable: false,
          },
          paid: {
            description: "Indicates whether the DfE has paid providers for any declarations attached to the statement.",
            type: :boolean,
            nullable: false,
          },
          created_at: {
            description: "The date the statement was created.",
            type: :string,
            format: :"date-time",
          },
          updated_at: {
            description: "The date the statement was last updated.",
            type: :string,
            format: :"date-time",
          },
        },
      },
    },
  },
}.freeze
