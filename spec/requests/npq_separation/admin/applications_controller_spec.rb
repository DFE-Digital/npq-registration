require "rails_helper"

RSpec.describe NpqSeparation::Admin::ApplicationsController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  describe "/npq_separation/admin/applications" do
    let(:fake_applications_find) { instance_double("Applications::Find", all: Application.limit(0)) }

    before do
      allow(Applications::Find).to receive(:new).and_return(fake_applications_find)

      sign_in_as_admin
    end

    it "calls Applications::Find.all" do
      get(npq_separation_admin_applications_path)

      expect(fake_applications_find).to have_received(:all).once
    end
  end
end
