module Helpers
  module JourneyStepHelper
    def choose_a_school(js:, location:, name:)
      build_sample_schools

      expect_page_to_have(path: "/registration/find-school", submit_form: true) do
        page.fill_in "Where is your workplace located?", with: location
      end

      if js
        expect_page_to_have(path: "/registration/choose-school", submit_form: true) do
          expect(page).to have_text("Search for schools or 16 to 19 educational settings located in #{location}. If you work for a trust, enter one of their schools.")

          within ".npq-js-reveal" do
            page.fill_in "What’s the name of your workplace?", with: name
          end

          expect(page).to have_content("open #{location} school")

          page.find("#school-picker__option--0").click
        end
      else
        expect_page_to_have(path: "/registration/choose-school", submit_form: true) do
          expect(page).to have_text("Search for schools or 16 to 19 educational settings located in #{location}. If you work for a trust, enter one of their schools.")

          within ".npq-js-hidden" do
            page.fill_in "What’s the name of your workplace?", with: name
          end

          page.click_button("Continue")

          expect(page).to have_text("What’s the name of your workplace?")
          page.choose "open #{location} school"
        end
      end
    end

    def choose_a_childcare_provider(js:, location:, name:)
      if js
        expect_page_to_have(path: "/registration/choose-childcare-provider", submit_form: true) do
          expect(page).to have_text("What’s the name of your workplace?")
          expect(page).to have_text("Search for workplaces located in #{location}")
          within ".npq-js-reveal" do
            page.fill_in "What’s the name of your workplace?", with: "open"
          end

          expect(page).to have_content("open #{location} school")
          page.find("#nursery-picker__option--0").click
        end
      else
        expect_page_to_have(path: "/registration/choose-childcare-provider", submit_form: true) do
          expect(page).to have_text("Search for workplaces located in #{location}")

          within ".npq-js-hidden" do
            page.fill_in "What’s the name of your workplace?", with: name
          end

          page.click_button("Continue")

          expect(page).to have_text("What’s the name of your workplace?")
          page.choose "open #{location} school"
        end
      end
    end

    def stub_npq_funding_request(previously_funded:)
      stub_request(:get, "https://ecf-app.gov.uk/api/v1/npq-funding/1234567?npq_course_identifier=npq-senior-leadership")
        .with(
          headers: {
            "Authorization" => "Bearer ECFAPPBEARERTOKEN",
          },
        )
        .to_return(
          status: 200,
          body: ecf_funding_lookup_response(previously_funded:),
          headers: {
            "Content-Type" => "application/vnd.api+json",
          },
        )
    end

  private

    def build_sample_schools(location: "manchester", other_location: "newcastle")
      return if School.where(urn: [100_000, 100_001, 100_002]).exists?

      School.create!(urn: 100_000, name: "open #{location} school", address_1: "street 1", town: location, establishment_status_code: "1")
      School.create!(urn: 100_001, name: "closed #{location} school", address_1: "street 2", town: location, establishment_status_code: "2")
      School.create!(urn: 100_002, name: "open #{other_location} school", address_1: "street 3", town: other_location, establishment_status_code: "1")
    end
  end
end
