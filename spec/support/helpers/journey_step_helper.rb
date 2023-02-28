module Helpers
  module JourneyStepHelper
    def choose_a_workplace(js:, location:, name:)
      build_sample_schools

      expect_page_to_have(path: "/registration/find-school", submit_form: true) do
        page.fill_in "Where is your workplace located?", with: location
      end

      if js
        expect_page_to_have(path: "/registration/choose-school", submit_form: true) do
          expect(page).to have_text("Search for schools or 16 to 19 educational settings located in manchester. If you work for a trust, enter one of their schools.")

          within ".npq-js-reveal" do
            page.fill_in "What’s the name of your workplace?", with: name
          end

          expect(page).to have_content("open manchester school")

          page.find("#school-picker__option--0").click
          page.click_button("Continue")
        end
      else
        expect_page_to_have(path: "/registration/choose-school", submit_form: true) do
          expect(page).to have_text("Search for schools or 16 to 19 educational settings located in manchester. If you work for a trust, enter one of their schools.")

          within ".npq-js-hidden" do
            page.fill_in "What’s the name of your workplace?", with: name
          end

          page.click_button("Continue")

          expect(page).to have_text("What’s the name of your workplace?")
          page.choose "open manchester school"
        end
      end
    end

  private

    def build_sample_schools
      return if School.where(urn: [100_000, 100_001, 100_002]).exists?

      School.create!(urn: 100_000, name: "open manchester school", address_1: "street 1", town: "manchester", establishment_status_code: "1")
      School.create!(urn: 100_001, name: "closed manchester school", address_1: "street 2", town: "manchester", establishment_status_code: "2")
      School.create!(urn: 100_002, name: "open newcastle school", address_1: "street 3", town: "newcastle", establishment_status_code: "1")
    end
  end
end
