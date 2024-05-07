LIST_APPLICATIONS_FILTER = {
  v1: {
    description: "Filter applications to return more specific results",
    type: "object",
    properties: {
      cohort: {
        description: "Return only NPQ applications from the specified cohort.",
        type: "string",
        example: "2022",
      },
      updated_since: {
        description: "Return only records that have been updated since this date and time (ISO 8601 date format).",
        type: "string",
        example: "2021-05-13T11:21:55Z",
      },
    },
  },
}.tap { |h|
  h[:v2] = h[:v1]
  h[:v3] = h[:v1].merge({
    properties: {
      cohort: {
        description: "Return only NPQ applications from the specified cohort or cohorts. This is a comma delimited string of years.",
        type: "string",
        example: "2021,2022",
      },
      updated_since: {
        description: "Return only records that have been updated since this date and time (ISO 8601 date format).",
        type: "string",
        example: "2021-05-13T11:21:55Z",
      },
      participant_id: {
        description: "Return only NPQ applications from the specified participant or participants. This is comma delimited string of participant IDs.",
        type: "string",
        example: "7e5bcdbf-c818-4961-8da5-439cab1984e0,c2a7ef98-bbfc-48c5-8f02-d484071d2165",
      },
    },
  })
}.freeze
