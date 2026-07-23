require "rails_helper"

RSpec.feature "Work setting nested radios", :with_cohorts, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper

  let(:school_types) { ["Primary school (5 to 11)", "Secondary school (11 to 16)", "Post-16 provider (16 to 19)"] }
  let(:group) { "#registration-wizard-work-setting-a-school-conditional" }

  context "without JavaScript", :no_js do
    before { visit "/registration/work-setting" }

    scenario "renders the school types, so they do not rely on JavaScript" do
      school_types.each { |type| expect(page).to have_field(type) }
    end

    scenario "asks for a school type when only 'A school' is picked" do
      choose("A school")
      click_button("Continue")

      expect(page).to have_current_path("/registration/work-setting")
      within(".govuk-error-summary") do
        expect(page).to have_link("Select the type of school that you work in")
      end
      expect(page).to have_css(".govuk-error-message", text: "Select the type of school that you work in")
    end

    scenario "moves on once a school type is picked" do
      choose("Primary school (5 to 11)")
      click_button("Continue")

      expect(page).not_to have_current_path("/registration/work-setting")
    end
  end

  context "with JavaScript", :js do
    let(:collapsed_group) { "#{group}.govuk-radios__conditional--hidden" }

    before { visit "/registration/work-setting" }

    scenario "keeps the school types collapsed until 'A school' is picked" do
      expect(page).to have_css(collapsed_group, visible: :all)

      choose("A school", visible: :all)

      expect(page).to have_no_css(collapsed_group, visible: :all)
    end

    scenario "keeps the school types open after one of them is picked" do
      expect(page).to have_css(collapsed_group, visible: :all)

      choose("A school", visible: :all)
      choose("Primary school (5 to 11)", visible: :all)

      expect(page).to have_no_css(collapsed_group, visible: :all)
      expect(page).to have_no_checked_field("A school", visible: :all)
      expect(page).to have_checked_field("Primary school (5 to 11)", visible: :all)
    end

    scenario "collapses the school types again when another setting is picked" do
      choose("A school", visible: :all)
      choose("Primary school (5 to 11)", visible: :all)
      choose("Other", visible: :all)

      expect(page).to have_css(collapsed_group, visible: :all)
      expect(page).to have_no_checked_field("Primary school (5 to 11)", visible: :all)
    end
  end
end
