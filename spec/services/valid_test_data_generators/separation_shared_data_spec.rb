# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidTestDataGenerators::SeparationSharedData, :with_default_schedules do
  let(:lead_provider) { create(:lead_provider, name: described_class::SHARED_USERS.keys.sample) }
  let(:user_params) { described_class::SHARED_USERS[lead_provider.name] }
  let(:cohort) { create(:cohort, :current) }

  before do
    allow(Rails).to receive(:env) { environment.inquiry }
  end

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

      it "creates 6 users" do
        # Prevents participant id changes from being created and their
        # respective users being counted as part of this test.
        allow(Faker::Boolean).to receive(:boolean).and_return(true)

        expect {
          subject.populate
        }.to change(User, :count).by(6)
      end

      it "creates users with provided details" do
        subject.populate

        user_params.each do |params|
          user = User.find_by_email(params[:email])

          expect(user.full_name).to eq(params[:name])
          expect(user.trn).to eq(params[:trn])
          expect(user.date_of_birth.iso8601).to eq(params[:date_of_birth])

          if params[:ecf_id].present?
            expect(user.ecf_id).to eq(params[:ecf_id])
          end
        end
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

      it "creates participant id changes" do
        allow(Faker::Boolean).to receive(:boolean).and_return(false)

        expect {
          subject.populate
        }.to(change(ParticipantIdChange, :count))
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

      it "voids some declarations" do
        allow(Faker::Boolean).to receive(:boolean).and_return(false)

        expect {
          subject.populate
        }.to(change(Declaration.voided_state, :count).and(change(ParticipantOutcome.voided_state, :count)))
      end
    end
  end
end