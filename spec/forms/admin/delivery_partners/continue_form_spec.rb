# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::DeliveryPartners::ContinueForm, type: :model do
  subject(:form) { described_class.new(delivery_partner:, continue:) }

  let(:delivery_partner) { create(:delivery_partner) }
  let(:continue) { "no" }

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:continue).in_array(%w[yes no]) }
  end

  describe "#continue?" do
    subject(:continue) { form.continue? }

    context "when continue is 'yes'" do
      let(:continue) { "yes" }

      it { is_expected.to be true }
    end

    context "when continue is 'no'" do
      let(:continue) { "no" }

      it { is_expected.to be false }
    end
  end
end
