require "rails_helper"

RSpec.describe "one_off:create_user" do
  subject(:run_task) { Rake::Task["one_off:create_user"].invoke(ecf_id, email, full_name, date_of_birth) }

  let(:ecf_id) { SecureRandom.uuid }
  let(:email) { "new-user@example.com" }
  let(:full_name) { "New User" }
  let(:date_of_birth) { "2000-01-01" }

  after do
    Rake::Task["one_off:create_user"].reenable
  end

  it "creates a user with the given ecf_id, email, name and date of birth" do
    expect { run_task }
      .to change { User.find_by(ecf_id:, email:, full_name:, date_of_birth: Date.parse(date_of_birth)) }
      .from(nil)
      .to an_instance_of(User)
  end
end
