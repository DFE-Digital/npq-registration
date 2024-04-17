require "rails_helper"

RSpec.describe Applications::Query do
  describe "#applications" do
    let(:lead_provider) { create(:lead_provider) }

    it "returns all applications" do
      application1 = create(:application, lead_provider:)
      application2 = create(:application, lead_provider:)

      query = Applications::Query.new
      expect(query.applications).to contain_exactly(application1, application2)
    end

    it "orders applications by created_at in ascending order" do
      application1 = create(:application, lead_provider:)
      application2 = travel_to(1.hour.ago) { create(:application, lead_provider:) }
      application3 = travel_to(1.minute.ago) { create(:application, lead_provider:) }

      query = Applications::Query.new
      expect(query.applications).to eq([application2, application3, application1])
    end

    describe "filtering" do
      it "filters by lead provider" do
        application = create(:application, lead_provider:)
        create(:application, lead_provider: create(:lead_provider))

        query = Applications::Query.new(lead_provider:)
        expect(query.applications).to contain_exactly(application)
      end
    end
  end

  describe "#application" do
    let(:lead_provider) { create(:lead_provider) }

    it "returns the application for a `lead_provider`" do
      application = create(:application, lead_provider:)

      query = Applications::Query.new
      expect(query.application(id: application.ecf_id)).to eq(application)
    end

    it "raises an error if the application does not exist" do
      query = Applications::Query.new
      expect { query.application(id: "XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the application is not in the filtered query" do
      other_lead_provider = create(:lead_provider)
      other_application = create(:application, lead_provider: other_lead_provider)

      query = Applications::Query.new(lead_provider:)
      expect { query.application(id: other_application.ecf_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
