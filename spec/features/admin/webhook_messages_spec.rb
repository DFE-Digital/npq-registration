require "rails_helper"

RSpec.feature "Webhook messages", :no_js, type: :feature do
  include Helpers::AdminLogin

  let!(:webhook_message) { create(:get_an_identity_webhook_message) }

  before do
    sign_in_as(create(:admin))
  end

  scenario "listing webhook messages" do
    visit(admin_webhook_messages_path)

    expect(page).to have_css("h1", text: "Webhook messages")
    expect(page).to have_content(webhook_message.message_type)
    expect(page).to have_content(webhook_message.message_id)
    expect(page).to have_content(webhook_message.status)
  end

  scenario "filtering webhook messages by message type and status" do
    other_webhook_message = create(:trs_user_updated_webhook_message)

    visit(admin_webhook_messages_path)

    expect(page).to have_content(webhook_message.message_id)
    expect(page).to have_content(other_webhook_message.message_id)

    select "UserUpdated", from: "Message type"
    click_button "Search"

    expect(page).to have_content(webhook_message.message_id)
    expect(page).not_to have_content(other_webhook_message.message_id)

    select "one_login_user.updated", from: "Message type"
    select "Pending", from: "Status"
    click_button "Search"

    expect(page).to have_content(other_webhook_message.message_id)
    expect(page).not_to have_content(webhook_message.message_id)

    select "Failed", from: "Status"
    click_button "Search"

    expect(page).to have_content("No webhook messages found")
  end

  scenario "viewing a webhook message" do
    visit(admin_webhook_messages_path)
    click_link "View"

    expect(page).to have_css("h1", text: "Webhook message")
    expect(page).to have_content('"preferredName": "John Doe"')
  end

  scenario "enqueueing a webhook message for retrying processing" do
    visit(admin_webhook_messages_path)
    click_link "View"
    expect {
      click_link "Queue retry"
    }.to have_enqueued_job(::GetAnIdentity::ProcessWebhookMessageJob)
  end
end
