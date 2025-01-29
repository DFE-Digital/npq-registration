require "rails_helper"

RSpec.describe "update_application" do
  include_context "with default schedules"

  describe "accept" do
    subject(:run_task) { Rake::Task["update_application:accept"].invoke(application.ecf_id) }

    let(:application) { create(:application, :pending, cohort: create(:cohort, :current)) }

    it "accepts the application" do
      run_task
      expect(application.reload.lead_provider_approval_status).to eq "accepted"
    end
  end

  describe "revert_to_pending" do
    subject(:run_task) { Rake::Task["update_application:revert_to_pending"].invoke(application.ecf_id) }

    let(:application) { create(:application, :accepted) }

    it "reverts the application to pending" do
      run_task
      expect(application.reload.lead_provider_approval_status).to eq "pending"
    end
  end

  describe "change_lead_provider" do
    subject(:run_task) { Rake::Task["update_application:change_lead_provider"].invoke(application.ecf_id, new_lead_provider.id) }

    let(:application) { create(:application, :accepted, lead_provider: LeadProvider.first) }
    let(:new_lead_provider) { LeadProvider.last }

    it "changes the lead provider of the application" do
      run_task
      expect(application.reload.lead_provider).to eq(new_lead_provider)
    end
  end
end
