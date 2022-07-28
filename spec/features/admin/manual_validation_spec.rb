require "rails_helper"

RSpec.feature "manual validation", type: :feature do
  let(:admin) { create(:admin) }

  include_context "sign in as admin"

  before { page.click_link("Manual validation") }

  context "downloading records to be validated offline" do
    before do
      expect_any_instance_of(Services::Exporters::ManualValidation).to receive(:csv).and_return("csv")
      expect_any_instance_of(Admin::ManualValidationsController).to receive(:send_data).and_call_original
    end

    # we're not actually testing the whole download here as it's a bit involved
    # in an rspec feature, just ensuring the CSV is properly built and we're
    # not navigated away from the current page
    scenario "clicking the Download CSV button triggers a download" do
      expect(page).to have_current_path("/admin/manual-validation")
      click_on "Download CSV"
      expect(page).to have_current_path("/admin/manual-validation")
    end
  end

  context "uploading records where application ids have been matched to TRNs" do
    # there are three rows in the CSV, two that match the UUIDs below and
    # an extra that will be skipped.
    let(:validated_data) { "spec/fixtures/files/manual-validation-upload.csv" }

    let(:user_without_trn) { create(:user, trn: nil) }
    let(:user_with_trn) { create(:user) }

    before do
      create(:application, ecf_id: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee", user: user_without_trn)
      create(:application, ecf_id: "aaaaaaaa-bbbb-cccc-1111-222222222222", user: user_with_trn)
    end

    scenario "adding the file and clicking upload triggers the import process" do
      expect(page).to have_current_path("/admin/manual-validation")

      attach_file(Rails.root.join(validated_data))
      click_button "Continue"

      expect(page).to have_current_path("/admin/manual-validation")
      expect(page).to have_content("updated: 2")
      expect(page).to have_content("skipped: 1")

      expect(Application.find_by(ecf_id: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee").user.trn).to eql("1234567")
      expect(Application.find_by(ecf_id: "aaaaaaaa-bbbb-cccc-1111-222222222222").user.trn).to eql("2345678")
    end
  end
end
