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
        expect(page).to have_summary_item("Course start", latest_application.cohort.start_year)
        expect(page).to have_link("Start now", href: registration_wizard_show_path("course-start-date"))
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
