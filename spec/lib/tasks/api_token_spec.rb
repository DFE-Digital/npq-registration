require "rails_helper"

Rails.application.load_tasks

RSpec.describe "api_token:teacher_record_service:generate_token" do
  subject(:run_task) { Rake::Task["api_token:teacher_record_service:generate_token"].invoke }

  it "creates a new API token for the Teacher Record Service" do
    expect { subject }.to change { APIToken.where(scope: APIToken.scopes[:teacher_record_service]).count }.by(1)
  end
end
