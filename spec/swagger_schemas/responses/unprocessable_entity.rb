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
            example: "course_identifier",
          },
          detail: {
            type: :string,
            example: "The entered '#/course_identifier' is not recognised for the given participant. Check details and try again.",
          },
        },
      },
    },
  },
}.freeze
