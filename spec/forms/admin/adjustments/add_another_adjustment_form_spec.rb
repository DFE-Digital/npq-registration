# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Adjustments::AddAnotherAdjustmentForm, type: :model do
  include Rails.application.routes.url_helpers

  subject(:form) { described_class.new(statement:, add_another:) }

  let(:statement) { create(:statement) }
  let(:add_another) { "no" }

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:add_another).in_array(%w[yes no]) }
  end

  describe "#redirect_to" do
    subject(:redirect_to) { form.redirect_to }

    context "when add_another is 'yes'" do
      let(:add_another) { "yes" }

      it { is_expected.to eq new_npq_separation_admin_finance_statement_adjustment_path(statement) }
    end

    context "when add_another is 'no'" do
      let(:add_another) { "no" }

      it { is_expected.to eq npq_separation_admin_finance_statement_path(statement) }
    end
  end
end
