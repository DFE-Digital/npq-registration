PARTICIPANT_DECLARATION_REQUEST = {
  description: "A participant declaration data request",
  type: :object,
  properties: {
    type: {
      type: :string,
    },
  },
  enum: %w[
    participant-declaration
  ],
  attributes: {
    anyOf: [
      { "$ref": "#/components/schemas/ParticipantDeclarationStartedRequest" },
      { "$ref": "#/components/schemas/ParticipantDeclarationRetainedRequest" },
      { "$ref": "#/components/schemas/ParticipantDeclarationCompletedRequest" },
    ],
  },
}.freeze
