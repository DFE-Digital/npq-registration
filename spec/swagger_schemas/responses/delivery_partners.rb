DELIVERY_PARTNERS_RESPONSE = {
  v3: {
    description: "A list of delivery partners",
    type: :object,
    required: %i[data],
    properties: {
      data: {
        type: :array,
        items: { "$ref": "#/components/schemas/DeliveryPartner" },
      },
    },
  },
}.freeze
