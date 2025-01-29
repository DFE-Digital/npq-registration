require "rails_helper"

RSpec.describe "update_participant" do
  describe "withdraw" do
    subject(:run_task) { Rake::Task["update_participant:withdraw"].invoke(participant.ecf_id, application.ecf_id, "started-in-error") }

    let(:participant) { create(:user) }
    let(:application) { create(:application, :with_declaration, user: participant) }

    it "withdraws the application" do
      run_task
      expect(application.reload.training_status).to eq "withdrawn"
    end
  end
end
