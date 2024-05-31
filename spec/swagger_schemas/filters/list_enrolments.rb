LIST_ENROLMENTS_FILTER = {
  v2: {
    description: "Filter enrolments to return more specific results",
    type: "object",
    properties: {
      updated_since: {
        description: "Return only records that have been updated since this date and time (ISO 8601 date format).",
        type: "string",
        example: "2021-05-13T11:21:55Z",
      },
    },
  },
}.freeze
