LIST_PARTICIPANTS_FILTER = {
  v1: {
    description: "Filter applications to return more specific results",
    type: :object,
    properties: {
      updated_since: {
        description: "Return only records that have been updated since this date and time (ISO 8601 date format).",
        type: :string,
        example: "2021-05-13T11:21:55Z",
      },
    },
  },
}.tap { |h|
  h[:v2] = h[:v1]
  h[:v3] = h[:v1].merge({
    properties: {
      updated_since: {
        description: "Return only records that have been updated since this date and time (ISO 8601 date format).",
        type: :string,
        example: "2021-05-13T11:21:55Z",
      },
      training_status: {
        description: "Return only records that have this training status",
        type: :string,
        enum: Application.training_statuses.keys,
        example: Application.training_statuses.keys.first,
      },
      from_participant_id: {
        description: "Return only records that have this from Participant ID",
        type: :string,
        example: "7e5bcdbf-c818-4961-8da5-439cab1984e0",
      },
    },
  })
}.freeze
