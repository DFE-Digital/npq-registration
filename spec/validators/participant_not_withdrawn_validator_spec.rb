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

    context "when participant was withdrawn before declaration_date" do
      before do
        travel_to declaration_date - 10.days do
          application.application_states.create!(state: :withdrawn, lead_provider:)
          application.withdrawn_training_status!
        end
      end

      it { is_expected.to be_invalid }
    end

    context "when participant was withdrawn after declaration_date" do
      before do
        travel_to declaration_date + 10.days do
          application.application_states.create!(state: :withdrawn, lead_provider:)
          application.withdrawn_training_status!
        end
      end

      it { is_expected.to be_valid }
    end

    context "when participant was reinstated after being withdrawn" do
      let(:application) { create(:application, :withdrawn, lead_provider:) }

      before do
        application.application_states.create!(lead_provider:)
        application.active_training_status!
      end

      it { is_expected.to be_valid }
    end

    context "when participant was withdrawn by another lead provider" do
      before do
        application.application_states.create!(state: :withdrawn, lead_provider: LeadProvider.where.not(id: lead_provider.id).first)
        application.withdrawn_training_status!
      end

      it { is_expected.to be_valid }
    end
  end
end
