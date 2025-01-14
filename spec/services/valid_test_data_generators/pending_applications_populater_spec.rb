# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidTestDataGenerators::PendingApplicationsPopulater, :with_default_schedules do
  let(:lead_provider) { create(:lead_provider) }
  let(:cohort) { create(:cohort, :current) }

  before do
    allow(Rails).to receive(:env) { environment.inquiry }
  end

  subject { described_class.new(lead_provider:, cohort:, number_of_participants: 22) }

  describe "#populate" do
    context "when running in other environment other than sandbox or development" do
      let(:environment) { "test" }

      it "returns nil" do
        expect(subject.populate).to be_nil
        expect(Application.count).to eq(0)
      end
    end

    context "when running in development or sandbox environments" do
      let(:environment) { "sandbox" }

      it "creates participants" do
        subject.populate

        expect(User.count).to eq(22)
        expect(Application.count).to eq(22)
        expect(Application.where(lead_provider_approval_status: "pending").count).to eq(22)
        expect(Application.all.map(&:cohort).uniq.first).to eq(cohort)
        expect(Application.all.map(&:lead_provider).uniq.first).to eq(lead_provider)
      end
    end
  end
end
