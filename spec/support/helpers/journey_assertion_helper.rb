module Helpers
  module JourneyAssertionHelper
    def navigate_to_page(path:, submit_form: false, submit_button_text: "Continue", axe_check: true, &block)
      visit(path)

      expect_page_to_have(path:, submit_form:, submit_button_text:, axe_check:, &block)
    end

    def expect_page_to_have(path:, submit_form: false, click_continue: false, submit_button_text: "Continue", axe_check: true, &block)
      expect(page).to have_current_path(path)

      @steps_visited ||= []
      @steps_visited << page.current_path unless page.current_path == "/"

      if axe_check && Capybara.current_driver != :rack_test
        expect(page).to(be_accessible)
      end

      block.call if block_given?

      page.click_button(submit_button_text, visible: :visible) if submit_form
      page.click_link("Continue", visible: :visible) if click_continue
    end

    def expect_check_answers_page_to_have_answers(values)
      within(".govuk-summary-list") do
        values.each do |key, value|
          expect(page).to have_summary_item(key, value)
        end
      end
    end

    def expect_applicant_reached_end_of_journey(total_number_of_created_applications: 1, course_start: "Autumn 2026")
      latest_application.reload

      expect_page_to_have(path: "/accounts/user_registrations/#{latest_application.id}/registration-complete", submit_form: false) do
        expect(page).to have_text("Registration complete")
        expect(page).to have_text("Your Registration ID")
        expect(page).to have_text(latest_application.ecf_id)
        expect(page).to have_text("We have sent you a confirmation email")
        page.click_link("Review a summary of your registration")
      end

      expect_page_to_have(path: "/accounts/user_registrations/#{latest_application.id}", submit_form: false) do
        expect(page).to have_text("Registration ID: #{latest_application.ecf_id}")
        expect(page).to have_summary_item("Course start", course_start)
        expect(page).to have_link("Start now", href: registration_wizard_show_path("course-start-date"))
      end

      expect(User.count).to be(1)
      expect(Application.count).to be(total_number_of_created_applications)
    end

    # relies on the entire feature spec using expect_page_to_have to navigate
    def check_back_journey_is_correct(exclude_current_page: false)
      correct_order = %w[
        course-start-date
        check-funding
        teacher-catchment
        choose-your-npq
        funding-history
        ineligible-for-funding-previously-funded
        work-setting
        kind-of-nursery
        have-ofsted-urn
        choose-childcare-provider
        choose-private-childcare-provider
        childcare-provider-not-in-england
        choose-school
        school-not-in-england
        npqh-status
        ehco-new-headteacher
        ehco-unavailable
        maths-eligibility-teaching-for-mastery
        maths-understanding-of-approach
        senco-in-role
        senco-start-date
        your-employment
        your-employer
        itt-provider
        referred-by-return-to-teaching-adviser
        possible-funding
        ehco-possible-funding
        funding-eligibility-senco
        funding-eligibility-maths
        funding-your-ehco
        choose-your-provider
        share-provider
        check-answers
      ]
      steps_that_are_not_in_a_fixed_position = %w[ineligible-for-funding funding-your-npq]
      steps = @steps_visited.map { |path| path.split("/").last } - steps_that_are_not_in_a_fixed_position
      spec_missing_steps = (steps - correct_order)
      fail "unexpected step encountered: #{spec_missing_steps.join(',')}" if spec_missing_steps.any?

      ordered_steps = steps.sort { |x, y| correct_order.index(x) <=> correct_order.index(y) }
      fail "steps in incorrect order - #{steps.join(',')} should be: #{ordered_steps.join(',')}" unless steps == ordered_steps

      starting_path = page.current_path
      until page.current_path == "/registration/course-start-date"
        page.click_link("Back")
        back_steps ||= []
        back_steps << page.current_path
        fail "infinite loop detected in back journey: #{back_steps.join(',')}" if back_steps.length > 30
      end
      always_skipped_pages_going_back = [
        "/registration/choose-childcare-provider",
        "/registration/choose-private-childcare-provider",
        "/registration/choose-school",
        "/registration/have-ofsted-urn",
        "/registration/kind-of-nursery",
      ]
      steps_visited = exclude_current_page ? @steps_visited.excluding(starting_path) : @steps_visited
      expect(back_steps.reverse).to match_backlinks steps_visited.excluding(always_skipped_pages_going_back)
      visit starting_path
    end

    def expect_school_picker_to_have_selected(js:, school:)
      if js
        expect(page.find("#school-picker").value).to eq [school.name, school.address].join(" - ")
      else
        expect(page).to have_checked_field(school.name)
      end
    end

    def expect_childcare_provider_picker_to_have_selected(js:, nursery:)
      if js
        expect(page.find("#nursery-picker").value).to eq [nursery.name, nursery.address].join(" - ")
      else
        expect(page).to have_checked_field(nursery.name)
      end
    end

    def expect_private_childcare_provider_picker_to_have_selected(js:, nursery:)
      if js
        expect(page.find("#private-childcare-provider-picker").value).to eq [nursery.name, nursery.address].join(" - ")
      else
        expect(page).to have_checked_field(nursery.name)
      end
    end
  end
end
