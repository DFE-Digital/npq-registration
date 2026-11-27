require "rails_helper"

RSpec.feature "Webhook messages", :no_js, type: :feature do
  include Helpers::AdminLogin

  let(:legacy_webhook_message) { create(:legacy_get_an_identity_webhook_message, sent_at: 5.days.ago) }
  let(:old_user_updated_webhook_message) { create(:trs_user_updated_webhook_message, sent_at: 1.month.ago) }
  let(:user_updated_webhook_message) { create(:trs_user_updated_webhook_message, sent_at: 1.day.ago) }
  let(:old_trn_request_completed_webhook_message) { create(:trs_trn_request_completed_webhook_message, sent_at: 1.month.ago) }
  let(:trn_request_completed_webhook_message) { create(:trs_trn_request_completed_webhook_message, sent_at: 2.days.ago) }
  let(:old_person_deactivated_webhook_message) { create(:trs_person_deactivated_webhook_message, sent_at: 1.month.ago) }
  let(:person_deactivated_webhook_message) { create(:trs_person_deactivated_webhook_message, merged_with_trn: "4567890", sent_at: 3.days.ago) }

  before do
    legacy_webhook_message
    old_user_updated_webhook_message
    user_updated_webhook_message
    old_trn_request_completed_webhook_message
    trn_request_completed_webhook_message
    old_person_deactivated_webhook_message
    person_deactivated_webhook_message
    sign_in_as(create(:admin))
  end

  scenario "listing webhook messages" do
    visit(admin_webhook_messages_path)

    expect(page).to have_css("h1", text: "Webhook messages")
    expect(page).to have_content(legacy_webhook_message.message_type)
    expect(page).to have_content(legacy_webhook_message.message_id)
    expect(page).to have_content(legacy_webhook_message.status)
  end

  scenario "filtering webhook messages by message type and status" do
    visit(admin_webhook_messages_path)

    expect(page).to have_content(legacy_webhook_message.message_id)
    expect(page).to have_content(user_updated_webhook_message.message_id)

    select "UserUpdated", from: "Message type"
    click_button "Search"

    expect(page).to have_content(legacy_webhook_message.message_id)
    expect(page).not_to have_content(user_updated_webhook_message.message_id)

    select "one_login_user.updated", from: "Message type"
    select "Pending", from: "Status"
    click_button "Search"

    expect(page).to have_content(user_updated_webhook_message.message_id)
    expect(page).not_to have_content(legacy_webhook_message.message_id)

    select "Failed", from: "Status"
    click_button "Search"

    expect(page).to have_content("No webhook messages found")
  end

  scenario "filtering webhook messages by message contents" do
    visit(admin_webhook_messages_path)

    fill_in "Message contents", with: "3456789"
    click_button "Search"

    expect(page).to have_field("Message contents", with: "3456789")
    expect(page.all("tr.govuk-table__row").count).to eq 2
    expect(page).to have_content(old_person_deactivated_webhook_message.message_id)
  end

  scenario "filtering webhook message by date range" do
    visit(admin_webhook_messages_path)

    start_date = 2.weeks.ago
    fill_in "webhook_messages[sent_at_start(3i)]", with: start_date.day
    fill_in "webhook_messages[sent_at_start(2i)]", with: start_date.month
    fill_in "webhook_messages[sent_at_start(1i)]", with: start_date.year
    click_button "Search"

    expect(page).to have_field("webhook_messages[sent_at_start(3i)]", with: start_date.day)
    expect(page).to have_field("webhook_messages[sent_at_start(2i)]", with: start_date.month)
    expect(page).to have_field("webhook_messages[sent_at_start(1i)]", with: start_date.year)
    expect(page.all("tr.govuk-table__row").count).to eq 5

    end_date = 4.days.ago
    fill_in "webhook_messages[sent_at_end(3i)]", with: end_date.day
    fill_in "webhook_messages[sent_at_end(2i)]", with: end_date.month
    fill_in "webhook_messages[sent_at_end(1i)]", with: end_date.year
    click_button "Search"

    expect(page).to have_field("webhook_messages[sent_at_end(3i)]", with: end_date.day)
    expect(page).to have_field("webhook_messages[sent_at_end(2i)]", with: end_date.month)
    expect(page).to have_field("webhook_messages[sent_at_end(1i)]", with: end_date.year)
    expect(page.all("tr.govuk-table__row").count).to eq 2
  end

  scenario "viewing a webhook message" do
    visit(admin_webhook_messages_path)
    within(".govuk-table__body .govuk-table__row", match: :first) do
      click_link "View"
    end

    expect(page).to have_css("h1", text: "Webhook message")
    expect(page).to have_content('"emailAddress": "user@example.com"')
  end

  scenario "enqueueing a failed webhook message for retrying processing" do
    visit(admin_webhook_messages_path)
    select "Failed", from: "Status"
    click_button "Search"
    within(".govuk-table__body .govuk-table__row", match: :first) do
      click_link "View"
    end

    expect {
      click_link "Queue retry"
    }.to have_enqueued_job(::TeachingRecordSystem::ProcessWebhookMessageJob)
  end
end
