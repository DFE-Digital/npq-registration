# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Adjustments::AddAnotherAdjustmentForm, type: :model do
  subject(:form) { described_class.new(statement:, add_another:) }

  let(:statement) { create(:statement) }
  let(:add_another) { "no" }

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:add_another).in_array(%w[yes no]) }
  end

  describe "#adding_another_adjustment?" do
    subject(:adding_another_adjustment) { form.adding_another_adjustment? }

    context "when add_another is 'yes'" do
      let(:add_another) { "yes" }

      it { is_expected.to be true }
    end

    context "when add_another is 'no'" do
      let(:add_another) { "no" }

      it { is_expected.to be false }
    end
  end
end
