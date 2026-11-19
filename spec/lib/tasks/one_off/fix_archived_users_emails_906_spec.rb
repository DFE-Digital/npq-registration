# frozen_string_literal: true

require "rails_helper"

RSpec.describe "one_off:fix_archived_users" do
  subject(:run_task) { Rake::Task["one_off:fix_archived_users"].invoke("false") }

  let(:email) { "user@example.com" }
  let(:trn) { "1234567" }
  let(:most_recently_updated_user) { create(:user, :archived, :with_get_an_identity_id, email:, archived_email: email, trn:, trn_verified: true) }
  let(:older_user) { create(:user, :archived, email: "archived-2-#{email}", archived_email: email, trn:, trn_verified: true, updated_at: 2.days.ago) }
  let(:application) { create(:application, user: most_recently_updated_user) }
  let(:user) { most_recently_updated_user }
  let(:third_user_matching_trn) { create(:user, :with_verified_trn, trn:, created_at: 2.years.ago, email: "previously.empty@example.com") } # one user in production has this third match

  before do
    travel_to(2.days.ago) { older_user }
    travel_to(1.day.ago) { application }
    travel_to(1.year.ago) { third_user_matching_trn }
    most_recently_updated_user.update!(archived_at: 1.year.ago)
    older_user.update!(archived_at: 1.day.ago)
  end

  after { Rake::Task["one_off:fix_archived_users"].reenable }

  it "updates the email addresses of the archived users" do
    run_task
    expect(most_recently_updated_user.reload.email).to eq("archived-#{email}")
  end

  it "blanks the provider and UID of the archived users" do
    run_task
    expect(most_recently_updated_user.reload.provider).to be_nil
    expect(most_recently_updated_user.uid).to be_nil
  end
end
