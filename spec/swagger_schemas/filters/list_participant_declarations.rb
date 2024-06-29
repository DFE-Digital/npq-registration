LIST_PARTICIPANT_DECLARATIONS_FILTER = {
  v1: {
    description: "Refine participant declarations to return.",
    type: :object,
    properties: {
      participant_id: {
        description: "The unique id of the participant",
        type: :string,
        example: "7e5bcdbf-c818-4961-8da5-439cab1984e0",
      },
      updated_since: {
        description: "Return only records that have been updated since this date and time (ISO 8601 date format).",
        type: :string,
        example: "2021-05-13T11:21:55Z",
      },
    },
  },
}.tap { |h|
  h[:v2] = h[:v1]
  h[:v3] = h[:v1]
}.freeze
