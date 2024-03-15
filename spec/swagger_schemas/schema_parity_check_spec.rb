require "rails_helper"

Dir[Rails.root.join("spec/swagger_schemas/models/**/*.rb")].sort.each { |f| require f }

RSpec.describe "Verify parity of swagger schemas and serializers" do
  # Recursively checks fields/associations in the serializer and properties
  # of the schema to ensure parity between the two.
  def check_serializer_matches_schema(serializer, schema)
    serializer_view = serializer.reflections[:default]
    serializer_fields = serializer_view.fields
    serializer_associations = serializer_view.associations

    check_schema_is_defined_in_serializer(schema, serializer, serializer_fields, serializer_associations)
    check_serializer_fields_and_associations_are_defined_in_schema(schema, serializer, serializer_fields, serializer_associations)
  end

  def check_schema_is_defined_in_serializer(schema, serializer, serializer_fields, serializer_associations)
    # Check each property of the schema.
    schema.each_key do |key|
      # If the schema contains a 'properties' key, it is an association.
      if schema[key].key?(:properties)
        # Check if the serializer contains the association.
        expect(serializer_associations).to have_key(key), "serializer '#{serializer.name}' missing '#{key}' association that is present in the swagger schema"
      else
        # Check if the serializer contains the field.
        expect(serializer_fields).to have_key(key), "serializer '#{serializer.name}' missing '#{key}' field that is present in the swagger schema"
      end
    end
  end

  def check_serializer_fields_and_associations_are_defined_in_schema(schema, serializer, serializer_fields, serializer_associations)
    # Check each field of the serializer.
    serializer_fields.each_key do |key|
      # Check if the schema contain the field.
      expect(schema).to have_key(key), "swagger schema missing '#{key}' field that is present in the serializer '#{serializer.name}'"
    end

    # Check each association of the serializer.
    serializer_associations.each_key do |key|
      # Load the blueprint for the association serializer.
      association_serializer = serializer_associations[key].blueprint
      # Check if the schema contains the association.
      expect(schema).to have_key(key), "swagger schema missing '#{key}' association that is present in the serializer '#{serializer.name}'"
      # Check each field in the association.
      check_serializer_matches_schema(association_serializer, schema[key][:properties])
    end
  end

  # Loop through the seraializers and check if a corresponding swagger
  # schema is present and if the fields and associations match.
  Dir["app/serializers/api/**/*_serializer.rb"].each do |file|
    matches = file.match(%r{(v\d)/(.*)_serializer}).captures
    version, model = matches

    describe "#{version} #{model} serializer" do
      let(:serializer) { "API::#{version.upcase}::#{model.upcase_first}Serializer".constantize }
      let(:schema) { Object.const_get(model.upcase).dig(version.to_sym, :properties) }

      it "has a corresponding swagger schema" do
        expect(schema).to be_present, "swagger schema missing for serializer '#{serializer.name}'"
      end

      it "matches the corresponding swagger schema" do
        check_serializer_matches_schema(serializer, schema)
      end
    end
  end
end
