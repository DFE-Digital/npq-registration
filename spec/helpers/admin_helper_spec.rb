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
end