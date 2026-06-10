require "rails_helper"

# Test funding eligibility based on a CSV of scenarios
RSpec.describe FundingEligibility, :eligibility_scenarios do
  subject(:funding_eligibility) do
    described_class.new(
      cohort:,
      institution:,
      course:,
      inside_catchment:,
      user_ecf_id: user_ecf_id,
      approved_itt_provider:,
      new_headteacher: false,
      employment_type:,
      childminder:,
      preschool_class_as_part_of_school:,
      referred_by_return_to_teaching_adviser:,
      work_setting:,
    )
  end

  before do
    create(:cohort, :unfunded, description: "2026 spring")
    create(:cohort, :with_funding_cap, description: "2026 autumn")
  end

  scenarios = CSV.read(Rails.root.join("spec/fixtures/scenarios/eligibility_testing_scenarios.csv"), headers: true)

  scenarios.each do |scenario|
    work_setting_description = scenario["Work setting"]
    work_setting_type, work_setting = work_setting_description.split(" - ")
    cohort_description = scenario["Cohort"]
    works_in_england = scenario["Works in England"].presence || "no"
    course_description = scenario["NPQ"]
    already_registered_for_course = scenario["Already registered for this course"].presence || "no"
    on_rise_list = scenario["RISE list?"].presence || "no"
    on_pp50_list = scenario["PP50"].presence || "no"
    expected_eligibility = scenario["Expected eligibility value"]

    context "when Cohort: #{cohort_description}, " \
      "Works in England? #{works_in_england}, " \
      "Work setting: #{work_setting_description}, " \
      "Course: #{course_description}, " \
      "Already registered for course? #{already_registered_for_course}, " \
      "On RISE list? #{on_rise_list}, " \
      "On PP50 list? #{on_pp50_list}," \
      do

        let(:cohort) { Cohort.find_by(description: cohort_description) }
        let(:inside_catchment) { works_in_england == "yes" }
        let(:expected_eligibility) { scenario["Expected eligibility value"] }
        let(:employment_type) { nil }
        let(:childminder) { nil }
        let(:preschool_class_as_part_of_school) { nil }
        let(:referred_by_return_to_teaching_adviser) { nil }
        let(:institution) { build(:school, :funding_eligible_establishment_type_code) }
        let(:user) { build(:user, :with_teacher_auth) }
        let(:user_ecf_id) { user.ecf_id }
        let(:approved_itt_provider) { expected_eligibility == "yes (if on ITT provider list)" }

        let(:course) do
          case course_description
          when "leading behaviour and culture"
            Course.find_by(identifier: "npq-leading-behaviour-culture")
          when "leading teacher development"
            Course.find_by(identifier: "npq-leading-teaching-development")
          when "lead teaching and learning for a subject, year group or phase" # TODO: get rid fo this
            Course.find_by(identifier: "npq-leading-teaching")
          when "develop other teachers and support their professional growth" # TODO: get rid fo this
            Course.find_by(identifier: "npq-leading-teaching-development")
          when "special educational needs co-ordinator (senco)"
            Course.find_by(identifier: "npq-senco")
          else
            Course.find_by(identifier: "npq-#{course_description.tr(' ', '-')}")
          end
        end

        case [work_setting_type, work_setting].compact
        when %w[school]
          let(:work_setting) { Questionnaires::WorkSetting::A_SCHOOL }
        when ["16", "19 education setting"]
          let(:work_setting) { Questionnaires::WorkSetting::A_16_TO_19_EDUCATIONAL_SETTING }
        when ["early years or childcare", "local authority maintained nursery"]
          let(:work_setting) { "early_years_or_childcare" }
          let(:institution) { build(:school, :local_authority_nursery_school) }
        when ["early years or childcare", "childminder"]
          let(:work_setting) { "early_years_or_childcare" }
          let(:childminder) { true }
          let(:institution) { build(:private_childcare_provider) }
        when ["early years or childcare", "private nursery"]
          let(:work_setting) { "early_years_or_childcare" }
          let(:institution) { build(:private_childcare_provider) }
        when ["early years or childcare", "another early years setting"]
          let(:work_setting) { "early_years_or_childcare" }
          let(:institution) { build(:private_childcare_provider) }
        when ["early years or childcare", "pre-school class or nursery that's part of a school"]
          let(:preschool_class_as_part_of_school) { true }
          let(:work_setting) { "early_years_or_childcare" }
        when ["academy trust"]
          let(:work_setting) { Questionnaires::WorkSetting::AN_ACADEMY_TRUST }
        when ["another setting", "independent hospital education organisation"]
          let(:work_setting) { "another_setting" }
          let(:employment_type) { "hospital_school" }
        when ["another setting", "teacher employer by an LA to teach in more than one school"]
          let(:work_setting) { "another_setting" }
          let(:employment_type) { "local_authority_supply_teacher" }
        when ["another setting", "young offender institution"]
          let(:work_setting) { "another_setting" }
          let(:employment_type) { "young_offender_institution" }
        when ["another setting", "lead mentor for an accredited ITT provider"]
          let(:work_setting) { "another_setting" }
          let(:employment_type) { "lead_mentor_for_accredited_itt_provider" }
        when ["another setting", "virtual school"]
          let(:work_setting) { "another_setting" }
          let(:employment_type) { "local_authority_virtual_school" }
        when ["other", "referred by a RTTA"]
          let(:work_setting) { "other" }
          let(:institution) { nil }
          let(:referred_by_return_to_teaching_adviser) { true }
        when ["other", "not referred by a RTTA"]
          let(:work_setting) { "other" }
          let(:institution) { nil }
          let(:referred_by_return_to_teaching_adviser) { false }
        else
          fail "Unknown work setting type and work setting combination: #{work_setting_type}, #{work_setting}"
        end

        before do
          if already_registered_for_course == "yes"
            if cohort.zero_funding?
              create(:application, :accepted, user:, course:, cohort:)
            else
              create(:application, :with_funded_place, :accepted, user:, course:, cohort:)
            end
          end
          rise_list = on_rise_list == "yes"
          pp50_list = on_pp50_list == "yes"
          allow(institution).to receive(:rise?).and_return(true) if rise_list
          allow(institution).to receive(:pp50?).and_return(true) if pp50_list
        end

        it "returns eligible: #{expected_eligibility}" do
          case expected_eligibility&.strip
          when "yes"
            expect(funding_eligibility.funding_eligiblity_status_code).to eq(FundingEligibility::FUNDED_ELIGIBILITY_RESULT)
          when "yes (if on ITT provider list)"
            expect(approved_itt_provider).to be true
            expect(funding_eligibility.funding_eligiblity_status_code).to eq(FundingEligibility::FUNDED_ELIGIBILITY_RESULT)
          when "subject to review"
            expect(funding_eligibility.subject_to_review?).to be true
          when "no"
            expect(funding_eligibility.funded?).to be false
          else
            fail "unexpected eligibility value in CSV: #{expected_eligibility}"
          end
        end
      end
  end
end
