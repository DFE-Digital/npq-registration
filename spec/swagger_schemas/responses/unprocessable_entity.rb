UNPROCESSABLE_ENTITY_RESPONSE = {
  description: "The payload was not valid. See the errors for more information.",
  type: :object,
  properties: {
    errors: {
      type: :array,
      items: {
        type: :object,
        properties: {
          title: {
            type: :string,
            example: "example_attribute",
          },
          detail: {
            type: :string,
            example: "An '#/example_attribute' must be specified.",
          },
        },
      },
    },
  },
}.freeze
