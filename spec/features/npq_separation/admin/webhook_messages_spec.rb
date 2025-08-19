require "rails_helper"

RSpec.feature "Webhook messages", type: :feature do
  include Helpers::AdminLogin

  let!(:webhook_message) { create(:get_an_identity_webhook_message) }

  before do
    sign_in_as(create(:admin))
  end

  scenario "listing webhook messages" do
    visit(npq_separation_admin_webhook_messages_path)

    expect(page).to have_css("h1", text: "Webhook messages")
    expect(page).to have_content(webhook_message.message_type)
    expect(page).to have_content(webhook_message.message_id)
    expect(page).to have_content(webhook_message.status)
  end

  scenario "viewing a webhook message" do
    visit(npq_separation_admin_webhook_messages_path)
    click_link "View"

    expect(page).to have_css("h1", text: "Webhook message")
    expect(page).to have_content('"preferredName": "John Doe"')
  end
end
