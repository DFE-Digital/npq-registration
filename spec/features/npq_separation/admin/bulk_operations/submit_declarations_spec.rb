require "rails_helper"

RSpec.feature "submit declarations", :rack_test_driver, type: :feature do
  include Helpers::AdminLogin
  include Helpers::BulkOperations

  let(:admin) { create(:admin) }
  let(:filename) { File.basename(declarations_file.path) }

  before do
    create :cohort, :current
  end

  context "when not logged in" do
    scenario "Submit declarations page is inaccessible" do
      visit npq_separation_admin_bulk_operations_submit_declarations_path
      expect(page).to have_current_path(sign_in_path)
    end
  end

  context "when logged in as admin" do
    before { sign_in_as(admin) }

    scenario "submit declarations" do
      visit npq_separation_admin_path
      click_link "Bulk changes"
      click_link "Submit declarations"

      expect(page).to have_content "No files have been uploaded"

      attach_file "file", declarations_file.path
      click_button "Upload file"

      expect(page).to have_content "File #{filename} uploaded successfully"

      click_link filename
      within(".govuk-summary-list") do |summary_list|
        expect(summary_list).to have_summary_item("Filename", filename)
        expect(summary_list).to have_summary_item("Rows", "2")
        expect(summary_list).to have_summary_item("Created by", "#{admin.full_name} (#{admin.email})")
      end

      visit npq_separation_admin_bulk_operations_submit_declarations_path
      perform_enqueued_jobs do
        click_button "Submit declarations"
      end

      click_link filename
      within(".govuk-summary-list") do |summary_list|
        expect(summary_list).to have_summary_item("Filename", filename)
        expect(summary_list).to have_summary_item("Rows", "2")
        expect(summary_list).to have_summary_item("Created by", "#{admin.full_name} (#{admin.email})")
        expect(summary_list).to have_summary_item("Ran by", "#{admin.full_name} (#{admin.email})")
      end

      expect(page).to have_content "Declaration created successfully"
      expect(page).not_to have_button("Submit declarations")
      expect(Declaration.count).to eq(2)
      expect(ParticipantOutcome.count).to eq(1)

      declaration = Declaration.last
      expect(declaration.declaration_type).to eq("completed")

      outcome = ParticipantOutcome.last
      expect(outcome.state).to eq("passed")
      expect(outcome.declaration).to eq(declaration)
    end

    scenario "when the bulk operation has started but not finished" do
      visit npq_separation_admin_bulk_operations_submit_declarations_path
      attach_file "file", declarations_file.path
      click_button "Upload file"
      click_button "Submit declarations"
      click_link filename

      expect(page).to have_content "The bulk operation is in progress."
    end

    scenario "file validation" do
      visit npq_separation_admin_bulk_operations_submit_declarations_path
      attach_file "file", empty_file.path
      click_button "Upload"
      expect(page).to have_content "is empty"

      attach_file "file", wrong_format_file.path
      click_button "Upload"
      expect(page).to have_content "is wrong format"

      attach_file "file", declarations_file.path
      click_button "Upload"
      expect(page).to have_button "Submit declarations"
    end

    scenario "displays results for mixed success and failure" do
      # Create a CSV with one valid and one invalid participant
      participant = create(:user)
      cohort = create(:cohort, :current)
      course = create(:course, identifier: "leadership-development")
      lead_provider = create(:lead_provider)
      delivery_partner = create(:delivery_partner)

      schedule = create(:schedule, cohort: cohort, course_group: course.course_group, allowed_declaration_types: %w[started])
      create(:application, :accepted, user: participant, cohort: cohort, course: course, lead_provider: lead_provider, schedule: schedule)

      # Create required contracts and partnerships
      statement = create(:statement, cohort: cohort, lead_provider: lead_provider)
      create(:contract, statement: statement, course: course)
      create(:delivery_partnership, cohort: cohort, delivery_partner: delivery_partner, lead_provider: lead_provider)

      mixed_csv_content = <<~CSV
        participant_id,declaration_type,declaration_date,course_identifier,delivery_partner_id,lead_provider_name,has_passed
        #{participant.ecf_id},started,#{schedule.applies_from.rfc3339},#{course.identifier},#{delivery_partner.ecf_id},"#{lead_provider.name}",
        nonexistent-participant-id,started,#{(schedule.applies_from + 1.day).rfc3339},#{course.identifier},#{delivery_partner.ecf_id},"#{lead_provider.name}",
      CSV

      mixed_file = tempfile_with_bom(mixed_csv_content)
      mixed_filename = File.basename(mixed_file.path)

      visit npq_separation_admin_bulk_operations_submit_declarations_path
      attach_file "file", mixed_file.path
      click_button "Upload file"

      perform_enqueued_jobs do
        click_button "Submit declarations"
      end

      click_link mixed_filename

      # Check that it shows both success and failure
      expect(page).to have_content "Declaration created successfully"
      expect(page).to have_content "Participant not found"
      expect(Declaration.count).to eq(1) # Only one declaration should be created
    end
  end
end
