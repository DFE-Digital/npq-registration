DELIVERY_PARTNERS_SORTING_OPTIONS = {
  v3: {
    description: "Sort records being returned.",
    enum: [
      "name",
      "-name",
      "created_at",
      "-created_at",
      "updated_at",
      "-updated_at",
    ],
    default: "name",
    example: "created_at",
  },
}.freeze
