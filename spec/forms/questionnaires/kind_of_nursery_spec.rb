require "rails_helper"

RSpec.describe Questionnaires::KindOfNursery, type: :model do
  subject(:instance) { described_class.new }

  describe "validations" do
    it { is_expected.to validate_presence_of(:kind_of_nursery) }
    it { is_expected.to validate_inclusion_of(:kind_of_nursery).in_array(described_class::KIND_OF_NURSERY_OPTIONS) }
  end

  describe "#previous_step" do
    subject { instance.previous_step }

    it { is_expected.to be :work_setting }
  end

  describe "#next_step" do
    subject { instance.next_step }

    context "when the kind of nursery is a private nursery" do
      Questionnaires::KindOfNursery::KIND_OF_NURSERY_PRIVATE_OPTIONS.each do |private_nursery|
        context "when the kind of nursery is #{private_nursery}" do
          before { instance.kind_of_nursery = private_nursery }

          it { is_expected.to be :have_ofsted_urn }
        end
      end
    end

    context "when the kind of nursery is a public nursery" do
      Questionnaires::KindOfNursery::KIND_OF_NURSERY_PUBLIC_OPTIONS.each do |public_nursery|
        context "when the kind of nursery is #{public_nursery}" do
          before { instance.kind_of_nursery = public_nursery }

          it { is_expected.to be :choose_childcare_provider }
        end
      end
    end
  end
end
