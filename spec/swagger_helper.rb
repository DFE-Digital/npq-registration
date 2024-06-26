# frozen_string_literal: true

require "rails_helper"
require "api/version"

Dir[Rails.root.join("spec/swagger_schemas/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join("public/api/docs").to_s

  config.openapi_strict_schema_validation = true

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = API::Version.all.each_with_object({}) do |version, hash|
    hash["#{version}/swagger.yaml"] = {
      openapi: "3.0.1",
      info: {
        title: "NPQ Registration API",
        version:,
      },
      externalDocs: {
        description: "Find out more about Swagger",
        url: "https://swagger.io/",
      },
      paths: {},
      servers: [
        {
          url: "https://npq-registration-sandbox-web.teacherservices.cloud/",
        },
      ],
      components: {
        securitySchemes: {
          api_key: {
            description: "Bearer token",
            type: :apiKey,
            name: "Authorization",
            in: :header,
          },
        },
        schemas: {
          PaginationFilter: PAGINATION_FILTER,
          ListApplicationsFilter: LIST_APPLICATIONS_FILTER[version],
          ListEnrolmentsFilter: LIST_ENROLMENTS_FILTER[version],
          ListParticipantsFilter: LIST_PARTICIPANTS_FILTER[version],
          ListStatementsFilter: LIST_STATEMENTS_FILTER[version],
          UnauthorisedResponse: UNAUTHORISED_RESPONSE,
          NotFoundResponse: NOT_FOUND_RESPONSE,
          IDAttribute: ID_ATTRIBUTE,
          ApplicationResponse: APPLICATION_RESPONSE[version],
          ApplicationsResponse: APPLICATIONS_RESPONSE[version],
          Application: APPLICATION[version],
          ApplicationAcceptRequest: APPLICATION_ACCEPT_REQUEST[version],
          ApplicationChangeFundedPlaceRequest: APPLICATION_CHANGE_FUNDED_PLACE_REQUEST,
          EnrolmentsCsvResponse: ENROLMENTS_CSV_RESPONSE[version],
          EnrolmentCsv: ENROLMENT_CSV[version],
          DeclarationsCsvResponse: DECLARATIONS_CSV_RESPONSE[version],
          DeclarationCsv: DECLARATION_CSV[version],
          ApplicationsCsvResponse: APPLICATIONS_CSV_RESPONSE[version],
          ApplicationCsv: APPLICATION_CSV[version],
          ParticipantResponse: PARTICIPANT_RESPONSE[version],
          ParticipantsResponse: PARTICIPANTS_RESPONSE[version],
          Participant: PARTICIPANT[version],
          StatementResponse: STATEMENT_RESPONSE[version],
          StatementsResponse: STATEMENTS_RESPONSE[version],
          Statement: STATEMENT[version],
          SortingOptions: SORTING_OPTIONS[version],
        }.compact,
      },
    }
  end

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
