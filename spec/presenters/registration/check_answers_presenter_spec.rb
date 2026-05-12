require "rails_helper"

RSpec.describe Registration::CheckAnswersPresenter do
  subject(:presenter) { described_class.new(state_store) }

  let(:state_store) { create(:registration_wizard, :completed).state_store }
  let(:answer) { described_class::Answer }

  describe "#answers" do
    subject { presenter.answers }

    it { is_expected.to include have_attributes(key: "Course start", value: "In autumn 2025") }
  end
end
