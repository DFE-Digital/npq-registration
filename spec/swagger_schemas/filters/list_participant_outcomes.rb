LIST_PARTICIPANT_OUTCOMES_FILTER = {
  description: "Filter NPQ outcomes to return more specific results",
  type: "object",
  properties: {
    created_since: {
      description: "Return only records that have been created since this date and time (ISO 8601 date format)",
      type: "string",
      example: "2021-05-13T11:21:55Z",
    },
  },
}.freeze
