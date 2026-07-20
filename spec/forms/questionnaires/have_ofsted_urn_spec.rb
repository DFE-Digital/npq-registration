require "rails_helper"

RSpec.describe Questionnaires::HaveOfstedUrn, type: :model do
  subject(:instance) { described_class.new(has_ofsted_urn:) }

  let(:has_ofsted_urn) { nil }

  describe "validations" do
    it { is_expected.to validate_presence_of(:has_ofsted_urn) }
    it { is_expected.to validate_inclusion_of(:has_ofsted_urn).in_array(%w[yes no]) }
  end

  describe "#next_step" do
    subject { instance.next_step }

    context "when has_ofsted_urn is 'yes'" do
      let(:has_ofsted_urn) { "yes" }

      it { is_expected.to eq(:choose_private_childcare_provider) }
    end

    context "when has_ofsted_urn is 'no'" do
      let(:has_ofsted_urn) { "no" }

      it_behaves_like "showing the eligibility step"
    end
  end
end
