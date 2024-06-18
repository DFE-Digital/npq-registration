# This helper will attempt to extract the default example from the swagger file
# for a given schema. We do this so that we can easily override key response
# values for endpoints without hard coding the whole example data in the spec.
#
# It can tranverse nested schema references, object properties and array items
# to recursively construct the example.
#
# It expects the schema passed in to have a `properties` key (which should be the case for all
# of our schemas.
#
# Example usage to override the `status` attribute example in the `ApplicationResponse` schema:
#
# let(:response_example) do
#  extract_swagger_example(schema: "#/components/schemas/ApplicationResponse", version: :v1).tap do |example|
#   example[:data][:attributes][:status] = "accepted"
#  end
# end
module Helpers
  module SwaggerExampleParser
    def extract_swagger_example(schema:, version:)
      # Grab the schema from the correct version of the swagger file.
      schemas = RSpec.configuration.openapi_specs["#{version}/swagger.yaml"][:components][:schemas]
      schema_key = schema.split("/").last.to_sym
      schema = schemas[schema_key]

      # If the schema defines an object, we need to extract the example from its properties.
      if schema[:type] == :object || schema.key?(:properties)
        extract_swagger_properties(properties: schema[:properties], version:)
      # A nested schema may define a single property with an example (e.g. IDAttribute).
      elsif schema.key?(:example)
        schema[:example]
      end
    end

    def extract_swagger_properties(properties:, version:)
      properties.transform_values do |value|
        # If the property is a reference to another schema, we need to extract the example from that schema.
        if value.key?(:$ref)
          extract_swagger_example(schema: value[:$ref], version:)
        # If the value is an object we need to extract the properties from it.
        elsif value[:type] == :object || value.key?(:properties)
          extract_swagger_properties(properties: value[:properties], version:)
        # If the value is an array of items, we need to extract the example from the items properties.
        elsif value[:type] == :array || value.key?(:items)
          if value[:items].key?(:enum)
            [value[:items][:example]]
          else
            [extract_swagger_properties(properties: value[:items][:properties], version:)]
          end
        # If the value has an example, we're on an attribute and don't need to go any deeper.
        elsif value.key?(:example)
          value[:example]
        end
      end
    end
  end
end
