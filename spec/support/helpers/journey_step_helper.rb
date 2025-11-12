module Helpers
  module JourneyStepHelper
    def choose_a_school(js:, name:)
      if js
        navigate_to_page(path: "/registration/choose-school", submit_form: true) do
          within ".npq-js-reveal" do
            page.fill_in "What is the name of your workplace?", with: name
          end

          page.find("#school-picker__option--0").click
        end
      else
        navigate_to_page(path: "/registration/choose-school", submit_form: true) do
          within ".npq-js-hidden" do
            page.fill_in "What is the name of your workplace?", with: name
          end

          page.click_button("Continue")
          page.choose name
        end
      end
    end

    def choose_a_childcare_provider(js:, name:)
      if js
        navigate_to_page(path: "/registration/choose-childcare-provider", submit_form: true) do
          within ".npq-js-reveal" do
            page.fill_in "What is the name of your workplace?", with: "open"
          end

          page.find("#nursery-picker__option--0").click
        end
      else
        navigate_to_page(path: "/registration/choose-childcare-provider", submit_form: true) do
          within ".npq-js-hidden" do
            page.fill_in "What is the name of your workplace?", with: name
          end

          page.click_button("Continue")
          page.choose name
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
          expect(page).to have_text("Enter your or your employer’s unique reference number (URN)")

          within ".npq-js-reveal" do
            page.fill_in "private-childcare-provider-picker", with: provider.urn
          end

          expect(page).to have_content("#{provider.urn} - #{provider.name} - #{provider.address_1}, #{provider.town}")

          page.find("#private-childcare-provider-picker__option--0").click
        end
      else
        expect_page_to_have(path: "/registration/choose-private-childcare-provider", submit_form: true) do
          within(".npq-js-hidden") do
            page.fill_in("Enter your or your employer’s unique reference number (URN)", with: provider.urn)
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

    def choose_teacher_catchment(js:, region:)
      if js
        expect_page_to_have(path: "/registration/teacher-catchment", axe_check: false, submit_form: true) do
          page.choose(region, visible: :all)
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
        end
      end
    end
  end
end
