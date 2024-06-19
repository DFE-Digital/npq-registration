# frozen_string_literal: true

require "rails_helper"

RSpec.describe ParticipantNotWithdrawnValidator do
  let(:klass) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      validates :participant_id, participant_not_withdrawn: true

      attr_reader :application, :lead_provider, :declaration_date

      def self.model_name
        ActiveModel::Name.new(self, nil, "temp")
      end

      def initialize(application:, lead_provider:, declaration_date:)
        @application = application
        @lead_provider = lead_provider
        @declaration_date = declaration_date
      end
    end
  end

  describe "#validate" do
    let(:lead_provider) { LeadProvider.all.sample }
    let(:application) { create(:application, :accepted, lead_provider:) }
    let(:declaration_date) { Time.zone.now + 1.day }

    subject { klass.new(application:, lead_provider:, declaration_date:) }

    context "when application participant is active" do
      it { is_expected.to be_valid }
    end

    context "when participant withdrawn before declaration_date" do
      let(:application) { create(:application, :withdrawn, lead_provider:) }

      it { is_expected.to be_invalid }
    end

    context "when participant withdrawn after declaration_date" do
      let(:declaration_date) { Time.zone.now - 1.day }
      let(:application) { create(:application, :withdrawn, lead_provider:) }

      it { is_expected.to be_valid }
    end

    context "when participant reinstated after being withdrawn" do
      let(:application) { create(:application, :withdrawn, lead_provider:) }

      before do
        application.application_states.create!(lead_provider:)
        application.active!
      end

      it { is_expected.to be_valid }
    end
  end
end
