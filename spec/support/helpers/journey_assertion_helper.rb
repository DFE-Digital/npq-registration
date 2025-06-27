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
      check_answers_page = CheckAnswersPage.new

      expect(check_answers_page).to be_displayed

      summary_data = check_answers_page.summary_list.rows.map { |summary_item|
        [summary_item.key, summary_item.value]
      }.to_h

      expect(summary_data).to eql(values)
    end

    def expect_applicant_reached_end_of_journey(total_number_of_created_applications: 1)
      expect_page_to_have(path: "/accounts/user_registrations/#{latest_application.id}?success=true", submit_form: false) do
        expect(page).to have_text("Registration successfully submitted")
        expect(page).to have_text("Application ID: #{latest_application.ecf_id}")
        expect(page).to have_link("Register for another NPQ", href: /\/registration\/provider_check/)
      end

      expect(User.count).to be(1)
      expect(Application.count).to be(total_number_of_created_applications)
    end

    def check_back_journey_is_correct
      starting_path = page.current_path
      until page.current_path == "/registration/course-start-date"
        page.click_link("Back")
        back_steps ||= []
        back_steps << page.current_path
      end
      expect(back_steps.reverse).to eq @steps_visited
      visit starting_path
    end
  end
end
