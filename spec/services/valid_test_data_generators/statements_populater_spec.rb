# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidTestDataGenerators::StatementsPopulater do
  let(:lead_provider) { create(:lead_provider) }
  let(:cohort) { create(:cohort, start_year: 2021) }

  before { allow(Rails).to receive(:env) { environment.inquiry } }

  subject { described_class.new(lead_provider:, cohort:) }

  describe "#populate" do
    context "when running in other environment other than separation or development" do
      let(:environment) { "test" }

      it "returns nil" do
        expect(subject.populate).to be_nil
      end
    end

    context "when running in development or separation environments" do
      let(:environment) { "separation" }

      it "creates statements" do
        expect {
          subject.populate
        }.to change(Statement, :count).by(36)
      end

      it "creates statements for the given cohort" do
        subject.populate

        expect(Statement.all.map(&:cohort).uniq.first).to eq(cohort)
      end

      it "creates statements for the given lead provider" do
        subject.populate

        expect(Statement.all.map(&:lead_provider).uniq.first).to eq(lead_provider)
      end

      it "creates paid statements" do
        expect {
          subject.populate
        }.to(change { Statement.paid.count })
      end

      it "creates unpaid statements" do
        expect {
          subject.populate
        }.to(change { Statement.unpaid.count })
      end
    end
  end
end
