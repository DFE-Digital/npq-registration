# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::ChangeLeadProvider, type: :model do
  subject(:service) { described_class.new(application:, lead_provider_id:) }

  let(:application) { create(:application) }
  let(:lead_provider_id) { LeadProvider.for(course: application.course).last.id }

  describe "validation" do
    it { is_expected.to validate_presence_of :application }
    it { is_expected.to validate_presence_of(:lead_provider_id).with_message "Choose a course provider" }

    context "when lead_provider_id is not different to the current lead provider" do
      let(:lead_provider_id) { application.lead_provider.id }

      it { is_expected.not_to be_valid }
    end

    context "when the lead_provider_id is different" do
      let(:lead_provider_id) { LeadProvider.for(course: application.course).last.id }

      it { is_expected.to be_valid }
    end
  end

  describe "#change_lead_provider" do
    subject { service.change_lead_provider }

    context "when lead_provider_id is not different to the current lead provider" do
      let(:lead_provider_id) { application.lead_provider.id }

      it { is_expected.to be false }
    end

    context "when lead_provider_id is different to the current lead provider" do
      it "changes the lead provider" do
        expect { subject }.to change(application, :lead_provider_id).to(lead_provider_id)
      end

      it { is_expected.to be true }
    end
  end

  describe "#lead_provider_options" do
    it "includes all lead providers except the current lead provider" do
      expect(service.lead_provider_options).to match_array(
        LeadProvider.where.not(id: application.lead_provider.id).map { |lp| an_object_having_attributes(id: lp.id, name: lp.name) },
      )
    end
  end
end
