# Swagger

We document the API using the [OpenAPI specification](https://swagger.io/specification/) via the [rswag](https://github.com/rswag/rswag) gem and expose the documentation to users through [swagger-ui](https://github.com/swagger-api/swagger-ui).

## Versioning

We have a class `API::Version` that defines the available API versions. If you add a new version it will automatically generate a new `yaml` file, for example v5 would end up in `/public/api/docs/v5/swagger.yaml`.

You may need to add/configure schemas for the new version in `/spec/swagger_schemas`. You should be able to see the version-specific schemas in the `swagger_helper.rb`:

```
StatementsResponse: STATEMENTS_RESPONSE[version]
```

## Documenting

When adding a new controller/endpoint, you need to ensure there is a corresponding spec file in the `spec/api/docs` directory. Ensure to set the correct API version in the `describe` metadata:

```
RSpec.describe "Statements endpoint", type: :request, openapi_spec: "v3/swagger.yaml" do
...
end
```

The specs for generating the swagger documentation exist separately to our core set of request specs to avoid polluting them with `rswag` DSL. This does, however, mean that we will have some duplication where we test the same functionality in both places. To limit this we should keep the documentation specs to a minimum. We don't need to test the filtering for a list endpoint, for example - performing a basic request and including the filtering options in the DSL is enough.

## Schemas

At the moment we have to manually maintain the swagger schemas (for response objects, for example). These are found in `spec/swagger_schemas` and get pulled in through `swagger_helper.rb`. These are categorised as follows:

```
# Individual attributes that are common, for example `id`.
swagger_schemas/attributes

# Filter models, for example filtering the list of statements.
swagger_schemas/filters

# Models, these should each have a corresponding Blueprinter serializer.
swagger_schemas/models

# Response objects, typically one or more per model (returning a statement and returning a list of statements, for example)
swagger_schemas/responses
```

## Swagger UI

We currently have a simple controller that renders out a custom layout to pull in a JS pack containing `swagger-ui-dist`. This will boot Swagger UI using the version of the yaml file in the path, so `/api/docs/v3` will render `/api/docs/v3/swagger.yaml`.

We have to use `swagger-ui-dist` instead of `swagger-ui` as the latter didn't transpile properly with the outdated version of webpacker/webpack we used to have.

We plan on replacing Swagger UI with a more accessible/custom documentation solution in the future.
