require "rails_helper"

RSpec.describe Migration::Ecf::NpqApplication, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:participant_identity) }
    it { is_expected.to belong_to(:npq_lead_provider) }
    it { is_expected.to belong_to(:npq_course) }
    it { is_expected.to belong_to(:cohort).optional }
    it { is_expected.to have_one(:profile).class_name("ParticipantProfile").with_foreign_key(:id) }
    it { is_expected.to have_one(:user).through(:participant_identity) }
    it { is_expected.to have_one(:school).class_name("School").with_foreign_key(:urn).with_primary_key(:school_urn) }
  end

  describe "#ineligible_for_funding_reason" do
    context "when funded place is not set" do
      context "and it is eligible for funding" do
        subject { create(:ecf_migration_npq_application, eligible_for_funding: true, funded_place: nil) }

        it "returns nil" do
          expect(subject.ineligible_for_funding_reason).to be_nil
        end
      end

      context "when school/course combo is not applicable" do
        subject { create(:ecf_migration_npq_application, eligible_for_funding: false, funded_place: nil) }

        it "returns establishment-ineligible" do
          expect(subject.ineligible_for_funding_reason).to eql("establishment-ineligible")
        end
      end

      context "when there is a previously accepted application" do
        let(:npq_course) { create(:ecf_migration_npq_course, identifier: "npq-senior-leadership") }

        subject { create(:ecf_migration_npq_application, eligible_for_funding: true, npq_course:, funded_place: nil) }

        before do
          create(:ecf_migration_schedule_npq_leadership)

          create(
            :ecf_migration_npq_application,
            :accepted,
            participant_identity: subject.participant_identity,
            eligible_for_funding: true,
            funded_place: nil,
            npq_course: subject.npq_course,
            npq_lead_provider: subject.npq_lead_provider,
          )
        end

        it "returns previously-funded" do
          expect(subject.ineligible_for_funding_reason).to eql("previously-funded")
        end
      end

      context "when there is a previously accepted ASO and applying for EHC0" do
        let(:npq_aso_course) { create(:ecf_migration_npq_course, identifier: "npq-additional-support-offer") }
        let(:npq_ehco_course) { create(:ecf_migration_npq_course, identifier: "npq-early-headship-coaching-offer") }

        subject { create(:ecf_migration_npq_application, eligible_for_funding: true, funded_place: nil, npq_course: npq_ehco_course) }

        before do
          create(:ecf_migration_schedule_npq_support)
          create(:ecf_migration_schedule_npq_ehco)

          create(
            :ecf_migration_npq_application,
            :accepted,
            participant_identity: subject.participant_identity,
            eligible_for_funding: true,
            funded_place: nil,
            npq_course: npq_aso_course,
            npq_lead_provider: subject.npq_lead_provider,
          )
        end

        it "returns previously-funded" do
          expect(subject.ineligible_for_funding_reason).to eql("previously-funded")
        end
      end
    end

    context "when funded place is set to true" do
      context "and it is eligible for funding" do
        subject { create(:ecf_migration_npq_application, eligible_for_funding: true, funded_place: true) }

        it "returns nil" do
          expect(subject.ineligible_for_funding_reason).to be_nil
        end
      end

      context "when there is a previously accepted application" do
        let(:npq_course) { create(:ecf_migration_npq_course, identifier: "npq-senior-leadership") }

        subject { create(:ecf_migration_npq_application, eligible_for_funding: true, npq_course:, funded_place: true) }

        before do
          create(:ecf_migration_schedule_npq_leadership)

          create(
            :ecf_migration_npq_application,
            :accepted,
            participant_identity: subject.participant_identity,
            eligible_for_funding: true,
            funded_place: true,
            npq_course: subject.npq_course,
            npq_lead_provider: subject.npq_lead_provider,
          )
        end

        it "returns previously-funded" do
          expect(subject.ineligible_for_funding_reason).to eql("previously-funded")
        end
      end

      context "when there is a previously accepted ASO and applying for EHC0" do
        let(:npq_aso_course) { create(:ecf_migration_npq_course, identifier: "npq-additional-support-offer") }
        let(:npq_ehco_course) { create(:ecf_migration_npq_course, identifier: "npq-early-headship-coaching-offer") }

        subject { create(:ecf_migration_npq_application, eligible_for_funding: true, funded_place: true, npq_course: npq_ehco_course) }

        before do
          create(:ecf_migration_schedule_npq_support)
          create(:ecf_migration_schedule_npq_ehco)

          create(
            :ecf_migration_npq_application,
            :accepted,
            participant_identity: subject.participant_identity,
            eligible_for_funding: true,
            funded_place: true,
            npq_course: npq_aso_course,
            npq_lead_provider: subject.npq_lead_provider,
          )
        end

        it "returns previously-funded" do
          expect(subject.ineligible_for_funding_reason).to eql("previously-funded")
        end
      end
    end

    context "when funded place is set to false" do
      context "and it is eligible for funding even though funded place is not" do
        subject { create(:ecf_migration_npq_application, eligible_for_funding: true, funded_place: false) }

        it "returns nil" do
          expect(subject.ineligible_for_funding_reason).to be_nil
        end
      end

      context "when school/course combo is not applicable" do
        subject { create(:ecf_migration_npq_application, eligible_for_funding: false, funded_place: false) }

        it "returns establishment-ineligible" do
          expect(subject.ineligible_for_funding_reason).to eql("establishment-ineligible")
        end
      end

      context "when there is a previously ineligible accepted application" do
        let(:npq_course) { create(:ecf_migration_npq_course, identifier: "npq-senior-leadership") }

        subject { create(:ecf_migration_npq_application, eligible_for_funding: true, npq_course:, funded_place: false) }

        before do
          create(:ecf_migration_schedule_npq_leadership)

          create(
            :ecf_migration_npq_application,
            :accepted,
            participant_identity: subject.participant_identity,
            eligible_for_funding: true,
            funded_place: false,
            npq_course: subject.npq_course,
            npq_lead_provider: subject.npq_lead_provider,
          )
        end

        it "returns nil" do
          expect(subject.ineligible_for_funding_reason).to be_nil
        end
      end

      context "when there is a previously ineligible accepted ASO and applying for EHC0" do
        let(:npq_aso_course) { create(:ecf_migration_npq_course, identifier: "npq-additional-support-offer") }
        let(:npq_ehco_course) { create(:ecf_migration_npq_course, identifier: "npq-early-headship-coaching-offer") }

        subject { create(:ecf_migration_npq_application, eligible_for_funding: true, funded_place: false, npq_course: npq_ehco_course) }

        before do
          create(:ecf_migration_schedule_npq_support)
          create(:ecf_migration_schedule_npq_ehco)

          create(
            :ecf_migration_npq_application,
            :accepted,
            participant_identity: subject.participant_identity,
            eligible_for_funding: true,
            funded_place: false,
            npq_course: npq_aso_course,
            npq_lead_provider: subject.npq_lead_provider,
          )
        end

        it "returns nil" do
          expect(subject.ineligible_for_funding_reason).to be_nil
        end
      end
    end
  end
end
