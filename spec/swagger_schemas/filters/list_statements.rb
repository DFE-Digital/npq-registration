LIST_STATEMENTS_FILTER = {
  v3: {
    description: "Filter statements to return more specific results",
    type: "object",
    properties: {
      cohort: {
        description: "Return statements associated to the specified cohort or cohorts. This is a comma delimited string of years.",
        type: "string",
        example: "2021,2022",
      },
      updated_since: {
        description: "Return only records that have been updated since this date and time (ISO 8601 date format)",
        type: "string",
        example: "2021-05-13T11:21:55Z",
      },
    },
  },
}.freeze
