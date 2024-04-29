APPLICATIONS_CSV_RESPONSE = {
  description: "A list of NPQ applications in the Comma Separated Value (CSV) format",
  type: :string,
  required: %i[data],
  properties: {
    data: {
      type: :array,
      items: { "$ref": "#/components/schemas/ApplicationCsv" },
    },
  },
}.freeze
