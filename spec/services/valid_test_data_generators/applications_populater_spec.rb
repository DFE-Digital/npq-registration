# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidTestDataGenerators::ApplicationsPopulater, :with_default_schedules do
  let(:lead_provider) { create(:lead_provider) }
  let(:cohort) { create(:cohort, :current) }

  before do
    allow(Rails).to receive(:env) { environment.inquiry }
  end

  subject { described_class.new(lead_provider:, cohort:, number_of_participants: 30) }

  describe "#populate" do
    context "when running in other environment other than separation or development" do
      let(:environment) { "test" }

      it "returns nil" do
        expect(subject.populate).to be_nil
      end
    end

    context "when running in development or separation environments" do
      let(:environment) { "separation" }

      it "creates users # given in the params" do
        expect {
          subject.populate
        }.to change(User, :count).by(30)
      end

      it "creates applications" do
        expect {
          subject.populate
        }.to(change(Application, :count))
      end

      it "creates applications for the given cohort" do
        subject.populate

        expect(Application.all.map(&:cohort).uniq.first).to eq(cohort)
      end

      it "creates applications for the given lead provider" do
        subject.populate

        expect(Application.all.map(&:lead_provider).uniq.first).to eq(lead_provider)
      end

      it "creates accepted applications" do
        expect {
          subject.populate
        }.to(change { Application.accepted.count })
      end

      it "creates rejected applications" do
        expect {
          subject.populate
        }.to(change { Application.rejected.count })
      end

      it "creates eligible for funding applications" do
        expect {
          subject.populate
        }.to(change { Application.eligible_for_funding.count })
      end

      it "creates declarations" do
        expect {
          subject.populate
        }.to(change(Declaration, :count))
      end

      it "creates outcomes" do
        allow(Faker::Boolean).to receive(:boolean).and_return(false)

        expect {
          subject.populate
        }.to(change(ParticipantOutcome, :count))
      end
    end
  end
end
