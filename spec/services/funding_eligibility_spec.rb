require "rails_helper"

RSpec.describe FundingEligibility do
  subject(:funding_eligibility) do
    described_class.new_from_query_store(institution:,
                                         course:,
                                         inside_catchment:,
                                         trn: "1234567",
                                         get_an_identity_id: SecureRandom.uuid,
                                         approved_itt_provider:,
                                         lead_mentor: nil,
                                         new_headteacher: nil,
                                         query_store:)
  end

  let(:store) do
    {
      work_setting:,
      kind_of_nursery:,
      employment_type:,
      referred_by_return_to_teaching_adviser:,
      ehco_headteacher: new_headteacher,
      ehco_new_headteacher: new_headteacher,
    }.stringify_keys
  end

  let(:inside_catchment) { true }
  let(:approved_itt_provider) { nil }
  let(:institution) { nil }
  let(:work_setting) { nil }
  let(:kind_of_nursery) { nil }
  let(:employment_type) { nil }
  let(:referred_by_return_to_teaching_adviser) { nil }
  let(:new_headteacher) { "no" }
  let(:query_store) { RegistrationQueryStore.new(store:) }

  RSpec.shared_examples "funding eligibility" do |result|
    it "returns the funding eligibility status code #{result}" do
      expect(funding_eligibility.funding_eligiblity_status_code).to eq result
    end

    it "has a funding eligibility status description" do
      expect { funding_eligibility.get_description_for_funding_status }.not_to raise_error
    end
  end

  RSpec.shared_examples "general rules" do
    context "and the applicant is outside England" do
      let(:inside_catchment) { false }

      include_examples "funding eligibility", :not_in_england
    end

    context "and the applicant has previously received funding" do
      before do
        user = build(:user, :with_get_an_identity_id, uid: funding_eligibility.get_an_identity_id)
        create(:application, :with_funded_place, :accepted, user:, course:)
      end

      include_examples "funding eligibility", :previously_funded
    end
  end

  RSpec.shared_examples "funding eligibility status codes by course" do |course_results|
    course_results.each do |course_identifier, result|
      context "and the course is #{course_identifier}" do
        let(:course) { build(:course, course_identifier) }

        include_examples "general rules"
        include_examples "funding eligibility", result
      end
    end

    context "and the course is early headship coaching offer" do
      let(:course) { build(:course, :early_headship_coaching_offer) }

      include_examples "general rules"
      include_examples "funding eligibility", :not_new_headteacher_requesting_ehco

      context "and the applicant is a new headteacher" do
        let(:new_headteacher) { "yes" }

        include_examples "general rules"
        include_examples "funding eligibility", :funded
      end
    end
  end

  RSpec.shared_examples "school policy" do
    context "and the institution is an eligible establishment type" do
      before do
        allow(institution).to receive(:eligible_establishment?).and_return(true)
      end

      include_examples "funding eligibility status codes by course", {
        senco: :funded,
        headship: :funded,
        leading_primary_mathematics: :ineligible_establishment_not_a_pp50,
        leading_behaviour_culture: :ineligible_establishment_not_a_pp50,
        leading_literacy: :ineligible_establishment_not_a_pp50,
        leading_teaching: :ineligible_establishment_not_a_pp50,
        leading_teaching_development: :ineligible_establishment_not_a_pp50,
        senior_leadership: :ineligible_establishment_not_a_pp50,
        executive_leadership: :ineligible_establishment_not_a_pp50,
        early_years_leadership: :ineligible_establishment_not_a_pp50,
      }

      context "and the institution is on the RISE list" do
        before do
          allow(institution).to receive(:rise?).and_return(true)
        end

        include_examples "funding eligibility status codes by course", {
          senco: :funded,
          headship: :funded,
          leading_primary_mathematics: :funded,
          leading_behaviour_culture: :funded,
          leading_literacy: :funded,
          leading_teaching: :funded,
          leading_teaching_development: :funded,
          senior_leadership: :funded,
          executive_leadership: :funded,
          early_years_leadership: :funded,
        }
      end

      context "and the institution is on the PP50 list" do
        before do
          allow(institution).to receive(:pp50?).and_return(true)
        end

        include_examples "funding eligibility status codes by course", {
          senco: :funded,
          headship: :funded,
          leading_primary_mathematics: :funded,
          leading_behaviour_culture: :funded,
          leading_literacy: :funded,
          leading_teaching: :funded,
          leading_teaching_development: :funded,
          senior_leadership: :funded,
          executive_leadership: :funded,
          early_years_leadership: :funded,
        }
      end
    end

    context "and the institution is a non-eligible establishment type" do
      before do
        allow(institution).to receive(:eligible_establishment?).and_return(false)
      end

      ineligible = {
        senco: :ineligible_establishment_type,
        headship: :ineligible_establishment_type,
        leading_primary_mathematics: :ineligible_establishment_type,
        leading_behaviour_culture: :ineligible_establishment_type,
        leading_literacy: :ineligible_establishment_type,
        leading_teaching: :ineligible_establishment_type,
        leading_teaching_development: :ineligible_establishment_type,
        senior_leadership: :ineligible_establishment_type,
        executive_leadership: :ineligible_establishment_type,
        early_years_leadership: :ineligible_establishment_type,
      }

      include_examples "funding eligibility status codes by course", ineligible

      context "and the institution is on the PP50 list" do
        before do
          allow(institution).to receive(:pp50?).and_return(true)
        end

        include_examples "funding eligibility status codes by course", ineligible
      end
    end
  end

  describe "#funding_eligiblity_status_code" do
    subject { funding_eligibility.funding_eligiblity_status_code }

    before do
      allow_any_instance_of(PrivateChildcareProvider).to receive(:eyl_disadvantaged?).and_return(false)
      allow_any_instance_of(School).to receive(:la_disadvantaged_nursery?).and_return(false)
      allow_any_instance_of(School).to receive(:eyl_disadvantaged?).and_return(false)
      allow_any_instance_of(School).to receive(:pp50?).and_return(false)
      allow_any_instance_of(School).to receive(:rise?).and_return(false)
    end

    context "when the work setting is 'Early years or childcare'" do
      let(:work_setting) { "early_years_or_childcare" }

      default_eligibility = {
        senco: :early_years_invalid_npq,
        headship: :early_years_invalid_npq,
        leading_primary_mathematics: :early_years_invalid_npq,
        leading_behaviour_culture: :early_years_invalid_npq,
        leading_literacy: :early_years_invalid_npq,
        leading_teaching: :early_years_invalid_npq,
        leading_teaching_development: :early_years_invalid_npq,
        senior_leadership: :early_years_invalid_npq,
        executive_leadership: :early_years_invalid_npq,
        early_years_leadership: :not_entitled_ey_institution,
      }

      context "and the institution is a Local authority-maintained nursery" do
        let(:kind_of_nursery) { "local_authority_maintained_nursery" }
        let(:institution) { build(:school, :local_authority_nursery_school) }

        include_examples "funding eligibility status codes by course", default_eligibility.merge({
          senco: :ineligible_establishment_type,
          headship: :ineligible_establishment_type,
          early_years_leadership: :ineligible_establishment_type,
        })

        context "and the institution is on the LA disadvantaged nursery list" do
          before do
            allow(institution).to receive(:la_disadvantaged_nursery?).and_return(true)
          end

          include_examples "funding eligibility status codes by course", default_eligibility.merge({
            senco: :funded,
            headship: :funded,
            early_years_leadership: :funded,
          })
        end
      end

      context "and the institution is a pre-school or nursery" do
        let(:kind_of_nursery) { "preschool_class_as_part_of_school" }
        let(:institution) { build(:school) }

        include_examples "funding eligibility status codes by course", default_eligibility

        context "and the institution is on the EYL disadvantaged list" do
          before do
            allow(institution).to receive(:eyl_disadvantaged?).and_return(true)
          end

          include_examples "funding eligibility status codes by course", default_eligibility.merge({
            early_years_leadership: :funded,
          })
        end
      end

      context "and the institution is a private nursery" do
        let(:kind_of_nursery) { "private_nursery" }
        let(:institution) { build(:private_childcare_provider) }

        include_examples "funding eligibility status codes by course", default_eligibility

        context "and the institution is on the EYL disadvantaged list" do
          before do
            allow(institution).to receive(:eyl_disadvantaged?).and_return(true)
          end

          include_examples "funding eligibility status codes by course", default_eligibility.merge({
            early_years_leadership: :funded,
          })
        end
      end

      context "and the institution is a childminder" do
        let(:kind_of_nursery) { "childminder" }
        let(:institution) { build(:private_childcare_provider) }

        include_examples "funding eligibility status codes by course", default_eligibility.merge({
          early_years_leadership: :not_entitled_childminder,
        })

        context "and the institution is on the childminders list" do
          before do
            allow(institution).to receive(:on_childminders_list?).and_return(true)
          end

          include_examples "funding eligibility status codes by course", default_eligibility.merge({
            early_years_leadership: :funded,
          })
        end
      end

      context "and the institution is another early years setting" do
        let(:kind_of_nursery) { "another_early_years_setting" }
        let(:institution) { build(:private_childcare_provider) }

        include_examples "funding eligibility status codes by course", default_eligibility

        context "and the institution is on the EYL disadvantaged list" do
          before do
            allow(institution).to receive(:eyl_disadvantaged?).and_return(true)
          end

          include_examples "funding eligibility status codes by course", default_eligibility.merge({
            early_years_leadership: :funded,
          })
        end
      end
    end

    context "when the work setting is 'A school'" do
      let(:work_setting) { Questionnaires::WorkSetting::A_SCHOOL }
      let(:institution) { build(:school) }

      include_examples "school policy"
    end

    context "when the work setting is 'An academy trust'" do
      let(:work_setting) { Questionnaires::WorkSetting::AN_ACADEMY_TRUST }
      let(:institution) { build(:school) }

      include_examples "school policy"
    end

    context "when the work setting is 'A 16 to 19 educational setting'" do
      let(:work_setting) { Questionnaires::WorkSetting::A_16_TO_19_EDUCATIONAL_SETTING }
      let(:institution) { build(:school) }

      include_examples "school policy"
    end

    context "when the work setting is 'Another setting'" do
      let(:work_setting) { "another_setting" }

      default_eligibility = {
        senco: :subject_to_review,
        headship: :subject_to_review,
        leading_primary_mathematics: :ineligible_establishment_type,
        leading_behaviour_culture: :ineligible_establishment_type,
        leading_literacy: :ineligible_establishment_type,
        leading_teaching: :ineligible_establishment_type,
        leading_teaching_development: :ineligible_establishment_type,
        senior_leadership: :ineligible_establishment_type,
        executive_leadership: :ineligible_establishment_type,
        early_years_leadership: :ineligible_establishment_type,
      }

      context "and the employment type is a virtual school" do
        let(:employment_type) { "local_authority_virtual_school" }

        include_examples "funding eligibility status codes by course", default_eligibility.merge
      end

      context "and the employment type is a hospital school" do
        let(:employment_type) { "hospital_school" }

        include_examples "funding eligibility status codes by course", default_eligibility
      end

      context "and the employment type is a young offender institution" do
        let(:employment_type) { "young_offender_institution" }

        include_examples "funding eligibility status codes by course", default_eligibility
      end

      context "and the employment type is a local authority supply teacher" do
        let(:employment_type) { "local_authority_supply_teacher" }

        include_examples "funding eligibility status codes by course", default_eligibility
      end

      context "and the employment type is as a lead mentor for an accredited ITT provider" do
        let(:employment_type) { "lead_mentor_for_accredited_itt_provider" }

        default_eligibility = {
          senco: :not_lead_mentor_course,
          headship: :not_lead_mentor_course,
          leading_primary_mathematics: :not_lead_mentor_course,
          leading_behaviour_culture: :not_lead_mentor_course,
          leading_literacy: :not_lead_mentor_course,
          leading_teaching: :not_lead_mentor_course,
          leading_teaching_development: :ineligible_establishment_type,
          senior_leadership: :not_lead_mentor_course,
          executive_leadership: :not_lead_mentor_course,
          early_years_leadership: :not_lead_mentor_course,
        }

        include_examples "funding eligibility status codes by course", default_eligibility

        context "and the ITT provider is approved" do
          let(:approved_itt_provider) { true }

          include_examples "funding eligibility status codes by course", default_eligibility.merge({
            leading_teaching_development: :funded,
          })
        end
      end
    end

    context "when the work setting is 'Other'" do
      let(:work_setting) { "other" }

      include_examples "funding eligibility status codes by course", {
        senco: :ineligible_establishment_type,
        headship: :ineligible_establishment_type,
        leading_primary_mathematics: :ineligible_establishment_type,
        leading_behaviour_culture: :ineligible_establishment_type,
        leading_literacy: :ineligible_establishment_type,
        leading_teaching: :ineligible_establishment_type,
        leading_teaching_development: :ineligible_establishment_type,
        senior_leadership: :ineligible_establishment_type,
        executive_leadership: :ineligible_establishment_type,
        early_years_leadership: :ineligible_establishment_type,
      }

      context "and there is a return to teaching adviser referral" do
        let(:referred_by_return_to_teaching_adviser) { "yes" }

        include_examples "funding eligibility status codes by course", {
          senco: :referred_by_return_to_teaching_adviser,
          headship: :referred_by_return_to_teaching_adviser,
          leading_primary_mathematics: :referred_by_return_to_teaching_adviser,
          leading_behaviour_culture: :referred_by_return_to_teaching_adviser,
          leading_literacy: :referred_by_return_to_teaching_adviser,
          leading_teaching: :referred_by_return_to_teaching_adviser,
          leading_teaching_development: :referred_by_return_to_teaching_adviser,
          senior_leadership: :referred_by_return_to_teaching_adviser,
          executive_leadership: :referred_by_return_to_teaching_adviser,
          early_years_leadership: :referred_by_return_to_teaching_adviser,
        }
      end
    end

    context "when institution is mandatory but missing" do
      let(:work_setting) { Questionnaires::WorkSetting::A_SCHOOL }
      let(:course) { Course.first }

      it "raises an error" do
        expect { subject }.to raise_error(FundingEligibility::MissingMandatoryInstitution)
      end
    end
  end

  describe "#get_description_for_funding_status" do
    subject { funding_eligibility.get_description_for_funding_status }

    let(:course) { build(:course, :early_headship_coaching_offer) }

    before do
      allow_any_instance_of(CourseHelper).to receive(:localise_sentence_embedded_course_name).with(course).and_return("Localised Course Name")
      allow(I18n).to receive(:t).with("funding_details.not_eligible_ehco", course_name: "Localised Course Name").and_return("message")
    end

    it { is_expected.to eq "message" }
  end

  describe "#possible_funding_for_non_pp50_and_fe?" do
    subject { funding_eligibility.possible_funding_for_non_pp50_and_fe? }

    let(:course) { build((Course::IDENTIFIERS - Course::ONLY_PP50).first) }
    let(:institution) { build(:private_childcare_provider) }

    it { is_expected.to be_falsey }

    context "when the course is only PP50" do
      let(:course) { build(Course::ONLY_PP50.first) }

      it { is_expected.to be_falsey }
    end

    context "when the institution is a school" do
      let(:institution) { build(:school) }

      it { is_expected.to be_falsey }
    end

    context "when the course is only PP50 and the institution is a school" do
      let(:course) { build(Course::ONLY_PP50.first) }
      let(:institution) { build(:school) }

      it { is_expected.to be_truthy }
    end
  end
end
