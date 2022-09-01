module Helpers
  module JourneyAssertionHelper
    def navigate_to_page(path:, submit_form: false, submit_button_text: "Continue", axe_check: true, &block)
      visit(path)

      expect_page_to_have(path:, submit_form:, submit_button_text:, axe_check:, &block)
    end

    def expect_page_to_have(path:, submit_form: false, click_continue: false, submit_button_text: "Continue", axe_check: true, &block)
      expect(page.current_path).to eql(path)

      if axe_check && Capybara.current_driver != :rack_test
        expect(page).to(be_axe_clean)
      end

      block.call if block_given?

      page.click_button(submit_button_text) if submit_form
      page.click_link("Continue") if click_continue
    end

    def expect_check_answers_page_to_have_answers(values)
      check_answers_page = CheckAnswersPage.new

      expect(check_answers_page).to be_displayed

      summary_data = check_answers_page.summary_list.rows.map { |summary_item|
        [summary_item.key, summary_item.value]
      }.to_h

      expect(summary_data).to eql(values)
    end
  end
end
