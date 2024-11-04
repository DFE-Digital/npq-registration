# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "an application accept action" do
  context "when accepting an application" do
    let(:cohort) { create(:cohort, :current, funding_cap: true) }
    let(:course) { create(:course, :senior_leadership) }
    let!(:schedule) { create(:schedule, :npq_leadership_autumn, course_group: course.course_group, cohort:) }

    let(:resource) { create(:application, :pending, course:, cohort:, lead_provider: current_lead_provider, eligible_for_funding: true) }
    let(:params) { { data: { attributes: } } }
    let(:attributes) { { funded_place: true, schedule_identifier: schedule.identifier } }

    it "returns the updated attributes" do
      api_post(path(resource_id), params:)
      expect(response.status).to eq 200
      expect(parsed_response["data"]["id"]).to eq(resource_id)
      expect(parsed_response["data"]["attributes"]["status"]).to eq("accepted")
      expect(parsed_response["data"]["attributes"]["funded_place"]).to be(true)
    end
  end
end

RSpec.shared_examples "an application reject action" do
  context "when rejecting an application" do
    it "returns the updated attributes" do
      api_post(path(resource_id))
      expect(response.status).to eq 200
      expect(parsed_response["data"]["id"]).to eq(resource_id)
      expect(parsed_response["data"]["attributes"]["status"]).to eq("rejected")
    end
  end
end

RSpec.shared_examples "an application change funded place action" do
  let(:cohort) { create(:cohort, :current, funding_cap: true) }
  let(:course) { create(:course, :senior_leadership) }
  let!(:schedule) { create(:schedule, :npq_leadership_autumn, course_group: course.course_group, cohort:) }

  let(:resource) { create(:application, :accepted, course:, cohort:, funded_place: false, lead_provider: current_lead_provider, eligible_for_funding: true) }
  let(:params) { { data: { attributes: } } }
  let(:attributes) { { funded_place: true } }

  context "when changing funded place for a application" do
    it "returns the updated attributes" do
      schedule
      api_put(path(resource_id), params:)
      expect(response.status).to eq 200
      expect(parsed_response["data"]["id"]).to eq(resource_id)
      expect(parsed_response["data"]["attributes"]["funded_place"]).to be(true)
    end
  end
end
