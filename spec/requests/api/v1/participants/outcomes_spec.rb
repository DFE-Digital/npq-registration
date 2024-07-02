require "rails_helper"

RSpec.describe "Participants outcome endpoints", type: :request do
  describe("index") do
    before { api_get(api_v1_participants_outcomes_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end

  describe("create") do
    before { api_post(api_v1_participants_outcomes_path(123)) }

    specify { expect(response).to(be_method_not_allowed) }
  end
end
