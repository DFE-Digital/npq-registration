DELIVERY_PARTNER = {
  v3: {
    description: "A single delivery partner",
    type: :object,
    required: %i[id type attributes],
    properties: {
      id: {
        "$ref": "#/components/schemas/IDAttribute",
      },
      type: {
        description: "The data type",
        type: :string,
        example: "delivery-partner",
        enum: %w[
          delivery-partner
        ],
      },
      attributes: {
        properties: {
          name: {
            description: "The name of the delivery partner",
            type: :string,
            nullable: false,
            example: "Awesome Delivery Partner Ltd",
          },
          cohort: {
            description: "The starting years of the cohorts the delivery partner is valid for",
            type: :array,
            items: {
              type: :string,
              example: "2025",
            },
          },
          created_at: {
            description: "The date the delivery partner was created",
            type: :string,
            nullable: false,
            format: :"date-time",
            example: "2025-03-25T02:21:32.000Z",
          },
          updated_at: {
            description: "The date the delivery partner was last updated",
            type: :string,
            nullable: false,
            format: :"date-time",
            example: "2025-03-25T02:22:32.000Z",
          },
        },
      },
    },
  },
}.freeze
