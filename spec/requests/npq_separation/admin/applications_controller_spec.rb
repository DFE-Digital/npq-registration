require "rails_helper"

RSpec.describe NpqSeparation::Admin::ApplicationsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  describe "/npq_separation/admin/applications" do
    let(:fake_applications_query) { instance_double("Applications::Query", applications: Application.limit(0)) }

    before do
      allow(Applications::Query).to receive(:new).and_return(fake_applications_query)

      sign_in_as_admin
    end

    it "calls Applications::Query#applications" do
      get(npq_separation_admin_applications_path)

      expect(fake_applications_query).to have_received(:applications).once
    end
  end
end
