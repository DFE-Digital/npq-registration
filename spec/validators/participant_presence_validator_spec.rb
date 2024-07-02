# frozen_string_literal: true

require "rails_helper"

RSpec.describe ParticipantPresenceValidator do
  let(:klass) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      validates :participant_id, participant_presence: true

      attr_reader :participant

      def self.model_name
        ActiveModel::Name.new(self, nil, "temp")
      end

      def initialize(participant:)
        @participant = participant
      end
    end
  end

  describe "#validate" do
    subject { klass.new(participant:) }

    let(:participant) { build(:user) }

    context "with participant" do
      it "is valid" do
        expect(subject).to be_valid
      end
    end

    context "with no participant" do
      let(:participant) { nil }

      it "is invalid" do
        expect(subject).to be_invalid
      end

      it "has a meaningful error", :aggregate_failures do
        expect(subject).to be_invalid
        expect(subject.errors.first).to have_attributes(attribute: :participant_id, type: :invalid_participant)
      end
    end
  end
end
