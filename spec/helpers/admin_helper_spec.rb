require "rails_helper"

RSpec.describe AdminHelper, type: :helper do
  include GovukVisuallyHiddenHelper
  include GovukLinkHelper

  describe "#format_cohort" do
    subject { format_cohort(cohort) }

    let(:cohort) { FactoryBot.build(:cohort, start_year: 2019) }

    it "formats a cohort with the start year and second two digits of the end year separated with a slash" do
      expect(subject).to include("2019/20")
    end
  end

  describe "format_address" do
    subject { format_address(school) }

    let(:school) { build(:school, :with_address) }

    it { is_expected.to eq("#{school.address_1}<br>#{school.address_2}<br>#{school.address_3}<br>#{school.town}<br>#{school.county}<br>#{school.postcode}") }

    context "when the school has no address" do
      let(:school) { build(:school) }

      it { is_expected.to be_nil }
    end

    context "when the school has a partial address" do
      let(:school) { build(:school, :with_address, address_2: nil, address_3: " ") }

      it { is_expected.to eq("#{school.address_1}<br>#{school.town}<br>#{school.county}<br>#{school.postcode}") }
    end
  end
end
