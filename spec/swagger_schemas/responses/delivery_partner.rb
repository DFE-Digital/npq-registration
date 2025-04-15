DELIVERY_PARTNER_RESPONSE = {
  v3: {
    description: "A single delivery partner",
    type: :object,
    required: %i[data],
    properties: {
      data: {
        "$ref": "#/components/schemas/DeliveryPartner",
      },
    },
  },
}.freeze
