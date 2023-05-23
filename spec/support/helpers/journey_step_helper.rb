module Helpers
  module JourneyStepHelper
    def choose_a_school(js:, location:, name:)
      build_sample_schools

      expect_page_to_have(path: "/registration/find-school", submit_form: true) do
        page.fill_in "Where is your workplace located?", with: location
      end

      if js
        expect_page_to_have(path: "/registration/choose-school", submit_form: true) do
          expect(page).to have_text("Search for your school or 16 to 19 educational setting in #{location}. If you work for a trust, enter one of their schools.")

          within ".npq-js-reveal" do
            page.fill_in "What’s the name of your workplace?", with: name
          end

          expect(page).to have_content("open #{location} school")

          page.find("#school-picker__option--0").click
        end
      else
        expect_page_to_have(path: "/registration/choose-school", submit_form: true) do
          expect(page).to have_text("Search for your school or 16 to 19 educational setting in #{location}. If you work for a trust, enter one of their schools.")

          within ".npq-js-hidden" do
            page.fill_in "What’s the name of your workplace?", with: name
          end

          page.click_button("Continue")

          expect(page).to have_text("Search for your school or 16 to 19 educational setting in #{location}. If you work for a trust, enter one of their schools.")
          page.choose "open #{location} school"
        end
      end
    end

    def choose_a_childcare_provider(js:, location:, name:)
      if js
        expect_page_to_have(path: "/registration/choose-childcare-provider", submit_form: true) do
          expect(page).to have_text("What’s the name of your workplace?")
          expect(page).to have_text("Search for your workplace in #{location}")
          within ".npq-js-reveal" do
            page.fill_in "What’s the name of your workplace?", with: "open"
          end

          expect(page).to have_content("open #{location} school")
          page.find("#nursery-picker__option--0").click
        end
      else
        expect_page_to_have(path: "/registration/choose-childcare-provider", submit_form: true) do
          expect(page).to have_text("Search for your workplace in #{location}")

          within ".npq-js-hidden" do
            page.fill_in "What’s the name of your workplace?", with: name
          end

          page.click_button("Continue")

          expect(page).to have_text("Search for your workplace in #{location}")
          page.choose "open #{location} school"
        end
      end
    end

    def choose_a_private_childcare_provider(js:, urn:, name:)
      provider = PrivateChildcareProvider.create!(
        provider_urn: urn,
        provider_name: name,
        address_1: "street 1",
        town: "manchester",
        early_years_individual_registers: %w[CCR VCR EYR],
      )

      if js
        expect_page_to_have(path: "/registration/choose-private-childcare-provider", submit_form: true) do
          expect(page).to have_text("Enter your or your employer’s URN")

          within ".npq-js-reveal" do
            page.fill_in "private-childcare-provider-picker", with: provider.urn
          end

          expect(page).to have_content("#{provider.urn} - #{provider.name} - #{provider.address_1}, #{provider.town}")

          page.find("#private-childcare-provider-picker__option--0").click
        end
      else
        expect_page_to_have(path: "/registration/choose-private-childcare-provider", submit_form: true) do
          within(".npq-js-hidden") do
            page.fill_in("Enter your or your employer’s URN", with: provider.urn)
          end
        end

        expect_page_to_have(path: "/registration/choose-private-childcare-provider", submit_form: true) do
          page.choose([provider.urn, provider.name].compact.join(" - "))
        end
      end
    end

    def choose_an_itt_provider(js:, name:)
      label = "Enter the name of the ITT provider you are working with"

      expect_page_to_have(path: "/registration/itt-provider", submit_form: true) do
        if js
          page.fill_in(label, with: name)
        else
          page.select(name, from: label)
        end
      end

      page.click_button("Continue")
    end

    def choose_teacher_catchment(js:, region:, country_name:)
      if js
        expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
          page.choose(region, visible: :all)

          within "[data-module='app-country-autocomplete'" do
            page.fill_in "Which country do you teach in?", with: country_name.first(4)
          end

          expect(page).to have_content(country_name)
          page.find("#registration-wizard-teacher-catchment-country-field__option--0").click
        end
      else
        # NOTE: we have more than one 'Falkland Islands' in the list, assuming it's there
        #       because of the autocompletion. Either way, we can't select like this because
        #       we'll get an ambiguous match:
        #
        # select(country_name, from: "Which country do you teach in?")
        #
        # instead we need to find all matches and select the first
        expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
          page.choose(region)

          find("select#registration-wizard-teacher-catchment-country-field")
            .all("option", text: country_name)
            .first
            .select_option
        end
      end
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
