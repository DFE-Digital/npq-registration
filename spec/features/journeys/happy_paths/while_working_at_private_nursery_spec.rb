require "rails_helper"

RSpec.feature "Happy journeys", :no_js, :with_default_nursery, :with_default_schedules, :with_eligibility_list_entries, type: :feature do
  include Helpers::JourneyAssertionHelper
  include Helpers::JourneyStepHelper
  include ApplicationHelper

  include_context "with stubbed Teacher Auth OmniAuth responses"
  include_context "with stubbed Teaching Record System person API"

  before do
    create(:cohort, :next, :with_all_courses_for_provider, suffix: "b", lead_provider: LeadProvider.find_by(name: "Teach First"))
    create(:school, :eligible_with_urn_and_address)
  end

  ineligible_courses_that_do_not_have_optional_questions = Course.pluck(:identifier)
    .excluding(
      "npq-additional-support-offer",
      "npq-early-headship-coaching-offer",
      "npq-early-years-leadership",
      "npq-leading-primary-mathematics",
      "npq-senco",
    )
    .map { |identifier| I18n.t(identifier, scope: "course.name") }

  ineligible_courses_that_do_not_have_optional_questions.each do |course|
    context "with course #{course}" do
      let(:course) { course }

      scenario "registration journey while working at private nursery" do
        complete_journey_as_far_as_choosing_a_work_setting(course:, work_setting: "Early years or childcare")

        expect_page_to_have(path: "/registration/kind-of-nursery", submit_form: true) do
          page.choose("Private nursery", visible: :all)
        end

        expect_page_to_have(path: "/registration/have-ofsted-urn", submit_form: true) do
          expect(page).to have_text("Do you or your employer have an Ofsted unique reference number (URN)?")
          page.choose("Yes", visible: :all)
        end

        choose_a_private_childcare_provider(js: false, urn: default_nursery.provider_urn, name: default_nursery.name)

        expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
          expect(page).to have_text("You can go back and select the Early years leadership")
        end
      end
    end
  end

  context "with course npq-early-headship-coaching-offer" do
    let(:course) { I18n.t("npq-early-headship-coaching-offer", scope: "course.name") }

    scenario "registration journey while working at private nursery" do
      complete_journey_as_far_as_funding_history(course:)

      expect_page_to_have(path: "/registration/npqh-status", submit_form: true) do
        page.choose "I’m doing it", visible: :all
      end

      expect_page_to_have(path: "/registration/ehco-new-headteacher", submit_form: true) do
        expect(page).to have_selector "h1", text: "Are you a headteacher in your first 5 years of a headship?"
        page.choose "Yes", visible: :all
      end

      expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
        page.choose("Early years or childcare", visible: :all)
      end

      expect_page_to_have(path: "/registration/kind-of-nursery", submit_form: true) do
        page.choose("Private nursery", visible: :all)
      end

      expect_page_to_have(path: "/registration/have-ofsted-urn", submit_form: true) do
        expect(page).to have_text("Do you or your employer have an Ofsted unique reference number (URN)?")
        page.choose("Yes", visible: :all)
      end

      choose_a_private_childcare_provider(js: false, urn: default_nursery.provider_urn, name: default_nursery.name)

      expect_page_to_have(path: "/registration/possible-funding", submit_form: false) do
        expect(page).to have_text("You’re eligible for scholarship funding for the Early headship coaching offer")
      end
    end
  end

  context "with course npq-early-years-leadership" do
    let(:course) { I18n.t("npq-early-years-leadership", scope: "course.name") }

    scenario "registration journey while working at private nursery" do
      complete_journey_as_far_as_choosing_a_work_setting(course:, work_setting: "Early years or childcare")

      expect_page_to_have(path: "/registration/kind-of-nursery", submit_form: true) do
        page.choose("Private nursery", visible: :all)
      end

      expect_page_to_have(path: "/registration/have-ofsted-urn", submit_form: true) do
        expect(page).to have_text("Do you or your employer have an Ofsted unique reference number (URN)?")
        page.choose("Yes", visible: :all)
      end

      choose_a_private_childcare_provider(js: false, urn: default_nursery.provider_urn, name: default_nursery.name)

      expect_page_to_have(path: "/registration/possible-funding", submit_form: false) do
        expect(page).to have_text("You’re eligible for scholarship funding for the Early years leadership NPQ")
      end
    end
  end

  context "with course npq-leading-primary-mathematics" do
    let(:course) { I18n.t("npq-leading-primary-mathematics", scope: "course.name") }

    scenario "registration journey while working at private nursery" do
      complete_journey_as_far_as_funding_history(course:)

      expect_page_to_have(path: "/registration/maths-eligibility-teaching-for-mastery", submit_form: true) do
        page.choose("Yes", visible: :all)
      end

      expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
        page.choose("Early years or childcare", visible: :all)
      end

      expect_page_to_have(path: "/registration/kind-of-nursery", submit_form: true) do
        page.choose("Private nursery", visible: :all)
      end

      expect_page_to_have(path: "/registration/have-ofsted-urn", submit_form: true) do
        expect(page).to have_text("Do you or your employer have an Ofsted unique reference number (URN)?")
        page.choose("Yes", visible: :all)
      end

      choose_a_private_childcare_provider(js: false, urn: default_nursery.provider_urn, name: default_nursery.name)

      expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
        expect(page).to have_text("You can go back and select the Early years leadership")
      end
    end
  end

  context "with course npq-senco" do
    let(:course) { I18n.t("npq-senco", scope: "course.name") }

    scenario "registration journey while working at private nursery" do
      complete_journey_as_far_as_funding_history(course:)

      expect_page_to_have(path: "/registration/senco-in-role", submit_form: true) do
        expect(page).to have_selector "h1", text: "Do you work as a special educational needs co-ordinator (SENCO)?"
        page.choose "Yes", visible: :all
      end

      expect_page_to_have(path: "/registration/senco-start-date", submit_form: true) do
        expect(page).to have_selector "h1", text: "When did you become a SENCO?"
        page.fill_in "Month", with: "1"
        page.fill_in "Year", with: "2026"
      end

      expect_page_to_have(path: "/registration/work-setting", submit_form: true) do
        page.choose("Early years or childcare", visible: :all)
      end

      expect_page_to_have(path: "/registration/kind-of-nursery", submit_form: true) do
        page.choose("Private nursery", visible: :all)
      end

      expect_page_to_have(path: "/registration/have-ofsted-urn", submit_form: true) do
        expect(page).to have_text("Do you or your employer have an Ofsted unique reference number (URN)?")
        page.choose("Yes", visible: :all)
      end

      choose_a_private_childcare_provider(js: false, urn: default_nursery.provider_urn, name: default_nursery.name)

      expect_page_to_have(path: "/registration/ineligible-for-funding", submit_form: false) do
        expect(page).to have_text("You can go back and select the Early years leadership")
      end
    end
  end
end
