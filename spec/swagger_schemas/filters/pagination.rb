PAGINATION_FILTER = {
  description: "Pagination options to navigate through the list of results.",
  type: :object,
  properties: {
    page: {
      type: :integer,
      description: "The page number to paginate to in the collection. If no value is specified it defaults to the first page.",
      example: 1,
    },
    per_page: {
      type: :integer,
      description: "The number items to display on a page. Defaults to 100. Maximum is 3000, if the value is greater that the maximum allowed it will fallback to 3000.",
      example: 10,
    },
  },
}.freeze
