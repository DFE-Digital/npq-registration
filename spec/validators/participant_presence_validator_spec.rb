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

    let(:application) { create(:application, :accepted) }
    let(:participant) { application.user }

    context "with participant identity" do
      it "is valid" do
        expect(subject).to be_valid
      end
    end

    context "with no participant identity" do
      let(:participant) { nil }

      it "is invalid" do
        expect(subject).to be_invalid
      end

      it "has a meaningful error", :aggregate_failures do
        expect(subject).to be_invalid
        expect(subject.errors.messages_for(:participant_id)).to include("Your update cannot be made as the '#/participant_id' is not recognised. Check participant details and try again.")
      end
    end
  end
end
