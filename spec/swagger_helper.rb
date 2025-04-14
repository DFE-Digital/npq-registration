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
          url: "http://0.0.0.0:3000", # Replaced in hosted environments by config/initializers/swagger_server_url.rb
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
          ListParticipantDeclarationsFilter: LIST_PARTICIPANT_DECLARATIONS_FILTER[version],
          ListParticipantOutcomesFilter: LIST_PARTICIPANT_OUTCOMES_FILTER,
          ListStatementsFilter: LIST_STATEMENTS_FILTER[version],

          UnauthorisedResponse: UNAUTHORISED_RESPONSE,
          NotFoundResponse: NOT_FOUND_RESPONSE,
          BadRequestResponse: BAD_REQUEST_RESPONSE,
          UnprocessableEntityResponse: UNPROCESSABLE_ENTITY_RESPONSE,
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
          ParticipantResumeRequest: PARTICIPANT_RESUME_REQUEST,
          ParticipantDeferRequest: PARTICIPANT_DEFER_REQUEST,
          ParticipantWithdrawRequest: PARTICIPANT_WITHDRAW_REQUEST,
          ParticipantChangeScheduleRequest: PARTICIPANT_CHANGE_SCHEDULE_REQUEST,
          ParticipantOutcome: PARTICIPANT_OUTCOME[version],
          ParticipantOutcomeCreateRequest: PARTICIPANT_OUTCOME_CREATE_REQUEST,
          ParticipantOutcomeResponse: PARTICIPANT_OUTCOME_RESPONSE[version],
          ParticipantOutcomesResponse: PARTICIPANT_OUTCOMES_RESPONSE[version],
          StatementResponse: STATEMENT_RESPONSE[version],
          StatementsResponse: STATEMENTS_RESPONSE[version],
          Statement: STATEMENT[version],
          SortingOptions: SORTING_OPTIONS[version],

          ParticipantDeclaration: PARTICIPANT_DECLARATION[version],
          ParticipantDeclarationRequest: PARTICIPANT_DECLARATION_REQUEST,
          ParticipantDeclarationResponse: PARTICIPANT_DECLARATION_RESPONSE[version],
          ParticipantDeclarationsResponse: PARTICIPANT_DECLARATIONS_RESPONSE[version],
          ParticipantDeclarationStartedRequest: PARTICIPANT_DECLARATION_STARTED_REQUEST,
          ParticipantDeclarationRetainedRequest: PARTICIPANT_DECLARATION_RETAINED_REQUEST,
          ParticipantDeclarationCompletedRequest: PARTICIPANT_DECLARATION_COMPLETED_REQUEST,

          ListDeliveryPartnersFilter: LIST_DELIVERY_PARTNERS_FILTER[version],
          DeliveryPartner: DELIVERY_PARTNER[version],
          DeliveryPartnerResponse: DELIVERY_PARTNER_RESPONSE[version],
          DeliveryPartnersResponse: DELIVERY_PARTNERS_RESPONSE[version],
          DeliveryPartnersSortingOptions: DELIVERY_PARTNERS_SORTING_OPTIONS[version],
        }.compact,
      },
    }
  }.tap do |hash|
    v1_v2_participant_declaration_requests = {
      ParticipantDeclarationRequest: PARTICIPANT_DECLARATION_REQUEST,
      ParticipantDeclarationStartedRequest: PARTICIPANT_DECLARATION_STARTED_REQUEST,
      ParticipantDeclarationRetainedRequest: PARTICIPANT_DECLARATION_RETAINED_REQUEST,
      ParticipantDeclarationCompletedRequest: PARTICIPANT_DECLARATION_COMPLETED_REQUEST,
    }
    hash["v1/swagger.yaml"][:components][:schemas].merge!(v1_v2_participant_declaration_requests)
    hash["v2/swagger.yaml"][:components][:schemas].merge!(v1_v2_participant_declaration_requests)
    hash["v3/swagger.yaml"][:components][:schemas].merge!(
      ParticipantDeclarationRequest: V3_PARTICIPANT_DECLARATION_REQUEST,
      ParticipantDeclarationStartedRequest: V3_PARTICIPANT_DECLARATION_STARTED_REQUEST,
      ParticipantDeclarationRetainedRequest: V3_PARTICIPANT_DECLARATION_RETAINED_REQUEST,
      ParticipantDeclarationCompletedRequest: V3_PARTICIPANT_DECLARATION_COMPLETED_REQUEST,
    )
  end

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
