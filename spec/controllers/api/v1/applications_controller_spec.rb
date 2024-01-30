require "rails_helper"

RSpec.describe Api::V1::ApplicationsController, type: :request do
  describe(
    "index",
    openapi: {
      summary: "List all applications",
      description: <<~INDEX,
        Lorem ipsum dolor sit amet, officia excepteur ex fugiat reprehenderit
        enim labore culpa sint ad nisi Lorem pariatur mollit ex esse
        exercitation amet. Nisi anim cupidatat excepteur officia. Reprehenderit
        nostrud nostrud ipsum Lorem est aliquip amet voluptate voluptate dolor
        minim nulla est proident. Nostrud officia pariatur ut officia. Sit irure
        duis.
      INDEX
      tags: %w[v1 applications],
      required_request_params: %w[page],
      security: [{ "SomeToken" => "xyz" }],
    },
  ) do
    before { get(api_v1_applications_path) }

    specify { expect(response).to(be_ok) }
  end

  # describe("show") do
  #   before { get(api_v1_application_path(123)) }
  #
  #   specify { expect(response).to(be_method_not_allowed) }
  # end
  #
  # describe("accept") do
  #   before { post(api_v1_application_accept_path(123)) }
  #
  #   specify { expect(response).to(be_method_not_allowed) }
  # end
  #
  # describe("reject") do
  #   before { post(api_v1_application_reject_path(123)) }
  #
  #   specify { expect(response).to(be_method_not_allowed) }
  # end
end
