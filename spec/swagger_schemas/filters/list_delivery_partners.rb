LIST_DELIVERY_PARTNERS_FILTER = {
  v3: {
    description: "Filter delivery partners to return more specific results",
    type: "object",
    properties: {
      cohort: {
        description: "Return only delivery partners from the specified cohort.",
        type: "string",
        example: "2022",
      },
    },
  },
}.freeze
