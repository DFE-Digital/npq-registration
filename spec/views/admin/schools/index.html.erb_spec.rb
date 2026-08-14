require "rails_helper"

RSpec.describe "admin/schools/index.html.erb", type: :view do
  subject(:rendered) { Capybara.string(render) }

  before do
    assign(:schools, schools)

    without_partial_double_verification do
      allow(view).to receive(:current_admin).and_return admin
    end
  end

  let(:admin) { build_stubbed(:admin) }
  let(:local_authority) { create(:local_authority) }
  let(:urn) { "123546" }
  let(:ukprn) { "12354678" }

  let :school do
    create(:school, urn:, ukprn:).tap do
      create(:eligibility_list_entry, :pp50_school, identifier: urn)
      create(:eligibility_list_entry, :pp50_further_education, identifier: ukprn)
    end
  end

  let :childcare do
    create(:private_childcare_provider, provider_urn: urn) do
      create(:eligibility_list_entry, :childminder, identifier: urn)
    end
  end

  describe "Workplaces table" do
    subject { rendered.find(".govuk-table tbody tr:first-of-type") }

    context "with header row" do
      subject { rendered.find(".govuk-table thead tr") }

      let(:schools) { [] }

      it { is_expected.to have_css "th", text: "Workplace name" }
      it { is_expected.to have_css "th", text: "ID" }
      it { is_expected.to have_css "th", text: "URN (unique reference number)" }
      it { is_expected.to have_css "th", text: "UKPRN (UK provider reference number)" }
      it { is_expected.to have_css "th", text: "Local authority" }
      it { is_expected.to have_css "th", text: "Address" }
      it { is_expected.to have_css "th", text: "Eligibility lists" }
    end

    context "with a school" do
      let(:schools) { [school] }

      it { is_expected.to have_css "td", text: school.name }
      it { is_expected.to have_css "td", text: school.id }
      it { is_expected.to have_css "td", text: school.urn }
      it { is_expected.to have_css "td", text: school.ukprn }
      it { is_expected.to have_css "td", text: school.la_name }
      it { is_expected.to have_css "td", text: join_with_commas(school.address) }
      it { is_expected.to have_css "td li", count: 2 }
      it { is_expected.to have_css "td li", text: "PP50" }
      it { is_expected.to have_css "td li", text: "PP50FE" }
    end

    context "with a local authority" do
      let(:schools) { [local_authority] }

      it { is_expected.to have_css "td", text: local_authority.name }
      it { is_expected.to have_css "td", text: local_authority.id }
      it { is_expected.to have_css "td", text: local_authority.urn }
      it { is_expected.to have_css "td", text: local_authority.ukprn }
      it { is_expected.to have_css "td", text: local_authority.la_name }
      it { is_expected.to have_css "td", text: join_with_commas(local_authority.address) }
      it { is_expected.to have_css "td span", count: 0 }
    end

    context "with a private childcare provider" do
      let(:schools) { [childcare] }

      it { is_expected.to have_css "td", text: childcare.name }
      it { is_expected.to have_css "td", text: childcare.id }
      it { is_expected.to have_css "td", text: childcare.urn }
      it { is_expected.to have_css "td", text: childcare.ukprn }
      it { is_expected.to have_css "td", text: childcare.la_name }
      it { is_expected.to have_css "td", text: join_with_commas(childcare.town, childcare.county, childcare.postcode) }
      it { is_expected.to have_css "td li", count: 1 }
      it { is_expected.to have_css "td li", text: "Childminder" }
    end
  end
end
