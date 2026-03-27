require "rails_helper"

RSpec.feature "Showing Application timestamps in UK local time", :no_js, type: :feature do
  include Helpers::AdminLogin

  let(:next_year) { 1.year.from_now.year }
  let(:winter_timestamp) { Time.utc(next_year, 1, 1, 8, 15) }
  let(:summer_timestamp) { Time.utc(next_year, 7, 1, 11, 15) }
  let(:winter_application) { create(:application) }
  let(:summer_application) { create(:application) }

  before do
    travel_to(winter_timestamp) { winter_application }
    travel_to(summer_timestamp) { summer_application }
  end

  shared_examples "displays times in UK local time" do
    scenario "displays times in UK local time" do
      travel_to(timestamp) do
        sign_in_as create(:admin)

        visit(npq_separation_admin_applications_path)

        expect(page).to have_css("h1", text: "Applications")
        expect(page).to have_css("td", text: "1 Jan #{next_year} 8:15am")
        expect(page).to have_css("td", text: "1 Jul #{next_year} 12:15pm")
      end
    end
  end

  context "when viewing times in the winter" do
    let(:timestamp) { winter_timestamp }

    it_behaves_like "displays times in UK local time"
  end

  context "when viewing times in the summer" do
    let(:timestamp) { summer_timestamp }

    it_behaves_like "displays times in UK local time"
  end
end
