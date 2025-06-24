# frozen_string_literal: true

require "rails_helper"

RSpec.describe ParticipantIdCurrencyValidator do
  let(:klass) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      validates :participant_id, participant_id_currency: true

      attr_reader :participant_id

      def self.model_name
        ActiveModel::Name.new(self, nil, "temp")
      end

      def initialize(participant_id:)
        @participant_id = participant_id
      end
    end
  end

  describe "#validate" do
    subject { klass.new(participant_id:) }

    context "with the old changed participant_id" do
      let(:participant_id_change) { create(:participant_id_change) }
      let(:participant_id) { participant_id_change.from_participant_id }

      it "is invalid and returns a useful error" do
        expect(subject).to be_invalid
        expect(subject.errors.first).to have_attributes(
          attribute: :participant_id,
          type: :changed,
          options: {
            from_participant_id: participant_id_change.from_participant_id,
            to_participant_id: participant_id_change.to_participant_id,
          },
        )
      end
    end

    context "with the new participant_id" do
      let(:participant_id_change) { create(:participant_id_change) }
      let(:participant_id) { participant_id_change.to_participant_id }

      it { is_expected.to be_valid }
    end

    context "with an unchanged participant_id" do
      let(:participant_id) { create(:user).ecf_id }

      it { is_expected.to be_valid }
    end

    context "with unrecognised participant_id" do
      let(:participant_id) { SecureRandom.uuid }

      it { is_expected.to be_valid }
    end

    context "with no participant_id" do
      let(:participant_id) { nil }

      it { is_expected.to be_valid }
    end
  end
end
