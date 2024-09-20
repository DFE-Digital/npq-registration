# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidTestDataGenerators::SeparationSharedData, :with_default_schedules do
  let(:shared_users_data) { YAML.load_file(Rails.root.join("db/seeds/separation_shared_data.yml")) }
  let(:lead_provider) { create(:lead_provider, name: shared_users_data.keys.sample) }
  let(:user_params) { shared_users_data[lead_provider.name] }
  let(:cohort) { create(:cohort, :current) }

  before do
    allow(Rails).to receive(:env) { environment.inquiry }
    # Stub Faker and Courses here so we have all scenarios created regardless
    allow(Faker::Boolean).to receive(:boolean).and_return(false)
    allow(Course).to receive(:all).and_return([Course.find_by(identifier: "npq-headship"), Course.find_by(identifier: "npq-leading-literacy")])
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

        expect(Application.pluck(:cohort_id)).to all(eq(cohort.id))
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
        expect {
          subject.populate
        }.to(change(ParticipantIdChange, :count))
      end

      it "creates rejected applications" do
        expect {
          subject.populate
        }.to(change { Application.where(lead_provider_approval_status: "rejected").count })
      end

      it "creates eligible for funding applications" do
        allow(Faker::Boolean).to receive(:boolean).and_return(true)

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
