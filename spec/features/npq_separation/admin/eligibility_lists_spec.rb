require "rails_helper"

RSpec.feature "Updating eligibility lists", :no_js, type: :feature do
  include Helpers::AdminLogin

  let(:super_admin) { create(:super_admin) }
  let(:urn) { "100001" }
  let(:ukprn) { "10000001" }
  let(:fe_csv_file) { tempfile_with_bom("FE UKPRN\n#{ukprn}\n") }

  def csv_file(header)
    tempfile_with_bom("#{header}\n#{urn}\n")
  end

  before do
    create(:school, urn:)
    create(:school, ukprn:)
    create(:private_childcare_provider, provider_urn: urn)
    sign_in_as_super_admin
    visit npq_separation_admin_eligibility_lists_path
  end

  scenario "Updating PP50 Schools eligibility list" do
    expect(School.find_by(urn:).pp50?(Questionnaires::WorkSetting::A_SCHOOL)).to be false

    within "div#pp50-schools" do
      attach_file "eligibility_lists_update[file]", csv_file("PP50 School URN").path
      click_button "Update eligibility list"
    end

    expect(page).to have_content "Eligibility list updated"
    expect(School.find_by(urn:).pp50?(Questionnaires::WorkSetting::A_SCHOOL)).to be true
  end

  scenario "Updating PP50 FE eligibility list" do
    expect(School.find_by(ukprn:).pp50?(Questionnaires::WorkSetting::A_16_TO_19_EDUCATIONAL_SETTING)).to be false

    click_link "PP50 FE"
    within "div#pp50-fe" do
      attach_file "eligibility_lists_update[file]", fe_csv_file.path
      click_button "Update eligibility list"
    end

    expect(page).to have_content "Eligibility list updated"
    expect(School.find_by(ukprn:).pp50?(Questionnaires::WorkSetting::A_16_TO_19_EDUCATIONAL_SETTING)).to be true
  end

  scenario "Updating Childminders eligibility list" do
    expect(PrivateChildcareProvider.find_by(provider_urn: urn).on_childminders_list?).to be false

    click_link "Childminders"
    within "div#childminders" do
      attach_file "eligibility_lists_update[file]", csv_file("Childminder URN").path
      click_button "Update eligibility list"
    end

    expect(page).to have_content "Eligibility list updated"
    expect(PrivateChildcareProvider.find_by(provider_urn: urn).on_childminders_list?).to be true
  end

  scenario "Updating Disadvantaged Early Years Schools eligibility list" do
    expect(PrivateChildcareProvider.find_by(provider_urn: urn).eyl_disadvantaged?).to be false
    expect(School.find_by(urn:).eyl_disadvantaged?).to be false

    click_link "Disadvantaged EY"
    within "div#disadvantaged-ey" do
      attach_file "eligibility_lists_update[file]", csv_file("Disadvantaged EY School URN,Ofsted URN").path
      click_button "Update eligibility list"
    end

    expect(page).to have_content "Eligibility list updated"
    expect(PrivateChildcareProvider.find_by(provider_urn: urn).eyl_disadvantaged?).to be true
    expect(School.find_by(urn:).eyl_disadvantaged?).to be true
  end

  scenario "Updating Local Authority Disadvantaged Nurseries eligibility list" do
    expect(School.find_by(urn:).la_disadvantaged_nursery?).to be false

    click_link "LA Nurseries"
    within "div#la-nurseries" do
      attach_file "eligibility_lists_update[file]", csv_file("LA Nursery URN").path
      click_button "Update eligibility list"
    end

    expect(page).to have_content "Eligibility list updated"
    expect(School.find_by(urn:).la_disadvantaged_nursery?).to be true
  end

  scenario "Updating RISE eligibility list" do
    expect(School.find_by(urn:).rise?).to be false

    click_link "RISE"
    within "div#rise" do
      attach_file "eligibility_lists_update[file]", csv_file("RISE School URN").path
      click_button "Update eligibility list"
    end

    expect(page).to have_content "Eligibility list updated"
    expect(School.find_by(urn:).rise?).to be true
  end

  scenario "No file chosen" do
    within "div#pp50-schools" do
      click_button "Update eligibility list"
    end

    expect(page).to have_content "Please choose a file"
  end
end
