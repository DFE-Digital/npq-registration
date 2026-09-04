require "rails_helper"

RSpec.describe Questionnaires::NpqhStatus, type: :model do
  subject(:instance) { described_class.new(npqh_status:) }

  let(:npqh_status) { nil }

  it { is_expected.to validate_inclusion_of(:npqh_status).in_array(Questionnaires::NpqhStatus::VALID_NPQH_STATUS_OPTIONS) }

  describe "#previous_step" do
    subject { instance.previous_step }

    it { is_expected.to eq(:work_setting) }
  end

  describe "#next_step" do
    subject { instance.next_step }

    context "when npqh_status is none" do
      let(:npqh_status) { "none" }

      it { is_expected.to eq(:ehco_unavailable) }
    end

    context "when npqh_status is studying_npqh" do
      let(:npqh_status) { "studying_npqh" }

      it { is_expected.to eq(:ehco_new_headteacher) }
    end

    context "when npqh_status is completed_npqh" do
      let(:npqh_status) { "completed_npqh" }

      it { is_expected.to eq(:ehco_new_headteacher) }
    end
  end
end
