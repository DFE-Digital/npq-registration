V3_PARTICIPANT_DECLARATION_CHANGE_DELIVERY_PARTNER_REQUEST = {
  description: "A participant declaration change delivery partner request",
  type: :object,
  required: %w[data],
  properties: {
    data: {
      description: "A participant declaration change delivery partner request",
      type: :object,
      required: %w[type attributes],
      properties: {
        type: {
          type: :string,
          required: true,
          enum: %w[
            participant-declaration
          ],
          example: "participant-declaration",
        },
        attributes: {
          required: true,
          anyOf: [{
            description: "An NPQ completed participant declaration",
            type: :object,
            required: %i[delivery_partner_id],
            additionalProperties: false,
            properties: {
              participant_id: {
                description: "The unique id of the participant",
                type: :string,
                format: :uuid,
                required: true,
                nullable: false,
                example: "db3a7848-7308-4879-942a-c4a70ced400a",
              },
              declaration_type: {
                description: "The event declaration type",
                type: :string,
                required: true,
                nullable: false,
                enum: %w[completed],
                example: "completed",
              },
              delivery_partner_id: {
                description: "The delivery partner ID",
                type: :string,
                format: :uuid,
                required: true,
                nullable: false,
                example: "524df095-f9bf-4f9d-ba4c-772545a99e60",
              },
              secondary_delivery_partner_id: {
                description: "The secondary delivery partner ID",
                type: :string,
                format: :uuid,
                required: false,
                nullable: false,
                example: "f0de7abf-399b-4e68-83de-2c33b503810c",
              },
            },
            example: {
              delivery_partner_id: "db3a7848-7308-4879-942a-c4a70ced400a",
              secondary_delivery_partner_id: "f0de7abf-399b-4e68-83de-2c33b503810c",
            },
          }],
        },
      },
    },
  },
}.freeze
