require "rails_helper"

RSpec.describe Registration::CheckAnswersPresenter do
  subject(:presenter) { described_class.new(wizard) }

  let(:wizard) { create(:registration_wizard, :completed) }

  describe "#answers" do
    subject { presenter.answers }

    it { is_expected.to include have_attributes(label: "Course start", formatted_value: "Autumn 2026") }
  end
end
