PARTICIPANT_DECLARATION_REQUEST = {
  description: "A participant declaration data request",
  type: :object,
  required: %w[data],
  properties: {
    data: {
      description: "A participant declaration data request",
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
          anyOf: [
            { "$ref": "#/components/schemas/ParticipantDeclarationStartedRequest" },
            { "$ref": "#/components/schemas/ParticipantDeclarationRetainedRequest" },
            { "$ref": "#/components/schemas/ParticipantDeclarationCompletedRequest" },
          ],
        },
      },
    },
  },
}.freeze
