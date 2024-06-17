BAD_REQUEST_RESPONSE = {
  description: "The request body did not match the expected payload.",
  type: :object,
  properties: {
    errors: {
      type: :array,
      items: {
        type: :object,
        properties: {
          title: {
            type: :string,
            example: "Bad request",
          },
          detail: {
            type: :string,
            example: "correct json data structure required. See API docs for reference",
          },
        },
      },
    },
  },
}.freeze
