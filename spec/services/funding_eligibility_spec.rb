require "rails_helper"

RSpec.describe FundingEligibility do
  subject(:funding_eligibility) do
    described_class.new(institution:,
                        course:,
                        inside_catchment:,
                        trn:,
                        get_an_identity_id:,
                        approved_itt_provider:,
                        lead_mentor:,
                        new_headteacher:,
                        query_store:)
  end

  let(:course) { build(:course, :additional_support_offer) }
  let(:inside_catchment) { true }
  let(:trn) { "1234567" }
  let(:get_an_identity_id) { SecureRandom.uuid }
  let(:previously_funded) { false }
  let(:course_identifier) { course.identifier }
  let(:eyl_funding_eligible) { false }
  let(:approved_itt_provider) { nil }
  let(:lead_mentor) { nil }
  let(:eligible_ey_urn) { "EY364275" }
  let(:new_headteacher) { true }
  let(:work_setting) { Questionnaires::WorkSetting::A_SCHOOL }
  let(:query_store) { instance_double(RegistrationQueryStore, work_setting: work_setting) }
  let(:institution) { build(:school, :funding_eligible_establishment_type_code, urn: "100000") }

  RSpec.shared_examples "funding eligibility" do |funded:, status_code:, description: nil, ineligible_institution_type: false|
    it "returns funded? #{funded}" do
      expect(subject.funded?).to eq funded
    end

    it "returns funding_eligiblity_status_code #{status_code}" do
      expect(subject.funding_eligiblity_status_code).to eq status_code
    end

    it "returns get_description_for_funding_status" do
      expect(subject.get_description_for_funding_status).to eq description
    end

    it "returns ineligible_institution_type? as #{ineligible_institution_type}" do
      expect(subject.ineligible_institution_type?).to eq ineligible_institution_type
    end
  end

  Course::IDENTIFIERS.each do |identifier|
    context "studying #{identifier}" do
      let(:course) { Course.find_by(identifier: identifier) }

      it_behaves_like "funding eligibility", funded: true, status_code: :funded, description: I18n.t("funding_details.scholarship_eligibility")
    end
  end

  context "studying npq-early-years-leadership" do
    let(:course) { Course.find_by(identifier: "npq-early-years-leadership") }

    it_behaves_like "funding eligibility", funded: true, status_code: :funded, description: I18n.t("funding_details.scholarship_eligibility")
  end

  context "studying npq-early-headship-coaching-offer" do
    let(:course) { create(:course, :early_headship_coaching_offer) }

    context "when not in England" do
      let(:inside_catchment) { false }

      it_behaves_like "funding eligibility", funded: false, status_code: :not_in_england,
                                             description: I18n.t("funding_details.not_eligible_ehco", course_name: "the Early headship coaching offer")
    end

    context "when in England but not eligible" do
      let(:inside_catchment) { true }
      let(:new_headteacher) { false }

      it_behaves_like "funding eligibility", funded: false, status_code: :not_new_headteacher_requesting_ehco,
                                             description: I18n.t("funding_details.not_eligible_ehco", course_name: "the Early headship coaching offer")
    end

    context "when there is no institution and they are not a new headteacher according to the query store" do
      let(:institution) { nil }
      let(:query_store) { instance_double(RegistrationQueryStore, new_headteacher?: false) }

      # weird mix of status code being one thing, and the description being something else - not sure if this is correct
      it_behaves_like "funding eligibility", funded: false, status_code: :ineligible_institution_type,
                                             description: I18n.t("funding_details.not_eligible_ehco", course_name: "the Early headship coaching offer"),
                                             ineligible_institution_type: true
    end
  end

  context "when institution is a School" do
    %w[1 2 3 5 6 7 8 10 12 14 15 18 24 26 28 31 32 33 34 35 36 38 39 40 41 42 43 44 45 46].each do |eligible_gias_code|
      context "eligible establishment_type_code #{eligible_gias_code}" do
        let(:institution) { build(:school, establishment_type_code: eligible_gias_code, urn:) }
        let(:course) { build(:course, :headship) }
        let(:urn) { "123" }
        let(:cohort) { build(:cohort, :current) }

        it_behaves_like "funding eligibility", funded: true, status_code: :funded, description: I18n.t("funding_details.scholarship_eligibility")

        context "when previously funded" do
          let(:previously_funded) { true }

          before do
            user = build(:user, trn:)
            create(:application, :previously_funded, user:, course:)
          end

          it_behaves_like "funding eligibility", funded: false, status_code: :previously_funded, description: "You have already been allocated scholarship funding for the Headship NPQ."

          context "for 2023 or earlier cohort" do
            let(:cohort) { build(:cohort, start_year: 2023) }

            it_behaves_like "funding eligibility", funded: false, status_code: :previously_funded, description: "You have already been allocated scholarship funding for the Headship NPQ."
          end
        end

        context "when school offering funding for the NPQEYL course" do
          context "and school is on the eligible list" do
            let(:urn) { eligible_ey_urn }

            context "when user has selected the NPQEYL course" do
              let(:course) { build(:course, :early_years_leadership) }

              it_behaves_like "funding eligibility", funded: true, status_code: :funded, description: I18n.t("funding_details.scholarship_eligibility")
            end
          end

          context "when user has selected the NPQEYL course" do
            let(:course) { build(:course, :early_years_leadership) }

            it_behaves_like "funding eligibility", funded: false, status_code: :not_entitled_ey_institution, description: I18n.t("funding_details.not_entitled_ey_institution")
          end

          context "when user has not selected the NPQEYL course" do
            let(:course) { build(:course, :headship) }

            it_behaves_like "funding eligibility", funded: true, status_code: :funded, description: I18n.t("funding_details.scholarship_eligibility")
          end
        end
      end
    end

    %w[11 25 27 29 30 37 56].each do |ineligible_gias_code|
      context "ineligible establishment_type_code #{ineligible_gias_code}" do
        let(:institution) { build(:school, establishment_type_code: ineligible_gias_code, urn:) }
        let(:urn) { "123" }

        it_behaves_like "funding eligibility", funded: false, status_code: :ineligible_establishment_type, description: I18n.t("funding_details.ineligible_setting")

        context "when school offering funding for the NPQEYL course" do
          let(:urn) { eligible_ey_urn }

          context "when user has selected the NPQEYL course" do
            let(:course) { build(:course, :early_years_leadership) }

            it_behaves_like "funding eligibility", funded: true, status_code: :funded, description: I18n.t("funding_details.scholarship_eligibility")
          end

          context "when user has not selected the NPQEYL course" do
            let(:course) { build(:course, :additional_support_offer) }

            it_behaves_like "funding eligibility", funded: false, status_code: :ineligible_establishment_type, description: I18n.t("funding_details.ineligible_setting")
          end
        end
      end
    end

    context "when school is LA nursery" do
      let(:institution) { build(:school, :non_pp50, establishment_type_code: "15") }

      context "when LA disadvantaged nursery" do
        before do
          allow(institution).to receive(:la_disadvantaged_nursery?).and_return(true)
        end

        Course::IDENTIFIERS.each do |identifier|
          context "when user has selected the #{identifier} course" do
            let(:course) { build(:course, identifier:) }

            it_behaves_like "funding eligibility", funded: true, status_code: :funded, description: I18n.t("funding_details.scholarship_eligibility")
          end
        end
      end

      context "when not LA disadvantaged nursery" do
        before do
          allow(institution).to receive(:la_disadvantaged_nursery?).and_return(false)
        end

        {
          senco: [true, :funded, I18n.t("funding_details.scholarship_eligibility")],
          leading_primary_mathmatics: [true, :funded, I18n.t("funding_details.scholarship_eligibility")],
          headship: [true, :funded, I18n.t("funding_details.scholarship_eligibility")],
          senior_leadership: [false, :ineligible_establishment_not_a_pp50, I18n.t("funding_details.not_a_pp50")],
          early_years_leadership: [false, :not_entitled_ey_institution, I18n.t("funding_details.not_entitled_ey_institution")],
          leading_literacy: [false, :ineligible_establishment_not_a_pp50, I18n.t("funding_details.not_a_pp50")],
          # TODO: test the other 6 courses?
        }.each do |course, eligibility|
          context "when user has selected the #{course} course" do
            let(:course) { build(:course, course) }

            it_behaves_like "funding eligibility", funded: eligibility[0], status_code: eligibility[1], description: eligibility[2]
          end
        end
      end
    end
  end

  context "when there is no institution with at an approved ITT provider and they are a lead mentor" do
    let(:institution) { nil }
    let(:approved_itt_provider) { true }
    let(:lead_mentor) { true }

    context "and the course is NPQLTD" do
      let(:course) { build(:course, :leading_teaching_development) }

      it_behaves_like "funding eligibility", funded: true, status_code: :funded, description: I18n.t("funding_details.scholarship_eligibility")
    end

    context "and the course is not NPQLTD, NPQS or EHCO" do
      (Course::IDENTIFIERS - [Course::NPQ_LEADING_TEACHING_DEVELOPMENT, Course::NPQ_SENCO, Course::NPQ_EARLY_HEADSHIP_COACHING_OFFER]).each do |identifier|
        let(:course) { build(:course, identifier:) }

        it_behaves_like "funding eligibility", funded: false, status_code: :not_lead_mentor_course, description: "You’re not eligible for scholarship funding as you do not work in one of the eligible settings, such as state-funded schools."
      end
    end
  end

  context "when institution is a LocalAuthority" do
    let(:institution) { build(:local_authority) }

    it_behaves_like "funding eligibility", funded: true, status_code: :funded, description: I18n.t("funding_details.scholarship_eligibility")

    context "when previously funded" do
      let(:previously_funded) { true }

      before do
        user = build(:user, trn:)
        create(:application, :previously_funded, user:, course:)
      end

      it_behaves_like "funding eligibility", funded: false, status_code: :previously_funded, description: I18n.t("funding_details.previously_funded", course_name: "the Additional Support Offer NPQ")
    end
  end

  context "when institution is a PrivateChildcareProvider" do
    context "when does not meets all the funding criteria" do
      let(:institution) { build(:private_childcare_provider, :on_early_years_register) }
      let(:course) { build(:course, :early_years_leadership) }
      let(:inside_catchment) { true }
      let(:previously_funded) { true }

      context "when previously funded" do
        before do
          user = build(:user, trn:)
          create(:application, :previously_funded, user:, course:)
        end

        it_behaves_like "funding eligibility", funded: false, status_code: :previously_funded, description: I18n.t("funding_details.previously_funded", course_name: "the Early years leadership NPQ")
      end

      context "when outside catchment" do
        let(:inside_catchment) { false }

        it_behaves_like "funding eligibility", funded: false, status_code: :not_in_england, description: I18n.t("funding_details.inside_catchment")
      end

      context "when NPQ course is not Early Year Leadership" do
        let(:course) { build(:course, :additional_support_offer) }

        it_behaves_like "funding eligibility", funded: false, status_code: :early_years_invalid_npq, description: I18n.t("funding_details.ineligible_setting")
      end

      context "when institution is not on early years register" do
        let(:institution) { build(:private_childcare_provider, provider_urn: EY_OFSTED_URN_HASH.first.first, early_years_individual_registers: []) }
        let(:query_store) { instance_double(RegistrationQueryStore, childminder?: false) }

        it_behaves_like "funding eligibility", funded: false, status_code: :not_on_early_years_register, description: I18n.t("funding_details.no_Ofsted")
      end

      context "when the childminder is not on the childminders list" do
        let(:institution) { build(:private_childcare_provider, early_years_individual_registers: %w[EYR]) }
        let(:query_store) { instance_double(RegistrationQueryStore, childminder?: true) }

        it_behaves_like "funding eligibility", funded: false, status_code: :not_entitled_childminder, description: "You’re not eligible for scholarship funding for the NPQ as you or your employer is not registered on the Ofsted early years register or with a registered Childminder Agency."
      end

      context "when the childminder is on the childminders list" do
        let(:institution) { build(:private_childcare_provider, provider_urn: CHILDMINDERS_OFSTED_URN_HASH.first.first, early_years_individual_registers: %w[EYR]) }
        let(:query_store) { instance_double(RegistrationQueryStore, childminder?: true) }

        it_behaves_like "funding eligibility", funded: true, status_code: :funded, description: I18n.t("funding_details.scholarship_eligibility")
      end

      context "when the institution is an unknown class" do
        let(:unknown_instituion_class) { Class.new }
        let(:institution) { TestInstitutionClass.new }

        before do
          stub_const("TestInstitutionClass", unknown_instituion_class)
        end

        it_behaves_like "funding eligibility", funded: false, status_code: :ineligible_institution_type, description: I18n.t("funding_details.ineligible_setting"), ineligible_institution_type: true
      end
    end
  end

  context "when there is no institution" do
    let(:institution) { nil }
    let(:inside_catchment) { true }

    context "when user is referred by return to teaching adviser" do
      let(:query_store) { instance_double(RegistrationQueryStore, referred_by_return_to_teaching_adviser?: true) }

      it_behaves_like "funding eligibility", funded: false, status_code: :referred_by_return_to_teaching_adviser
    end

    describe "no_institution code" do
      let(:young_offender) { false }
      let(:hospital) { false }
      let(:works_in_other) { false }

      let(:query_store) do
        instance_double(RegistrationQueryStore,
                        young_offender_institution?: young_offender,
                        local_authority_supply_teacher?: false,
                        employment_type_local_authority_virtual_school?: false,
                        employment_type_hospital_school?: hospital,
                        referred_by_return_to_teaching_adviser?: false,
                        works_in_other?: works_in_other)
      end
      let(:course) { build(:course, :headship) }

      context "when user is working in young offender institution" do
        let(:young_offender) { true }

        it_behaves_like "funding eligibility", funded: false, status_code: :no_institution, ineligible_institution_type: true
      end

      context "when user is working in hospital school" do
        let(:hospital) { true }

        it_behaves_like "funding eligibility", funded: false, status_code: :no_institution, ineligible_institution_type: true
      end

      context "when user is working in other" do
        let(:works_in_other) { true }

        it_behaves_like "funding eligibility", funded: false, status_code: :ineligible_institution_type, description: I18n.t("funding_details.ineligible_setting"), ineligible_institution_type: true
      end

      context "when there is no query store" do
        let(:query_store) { nil }

        it_behaves_like "funding eligibility", funded: false, status_code: :no_institution, ineligible_institution_type: true
      end
    end
  end

  context "when school is only on one list but provides both normal and FE" do
    let(:urn) { "123" }
    let(:ukprn) { "123" }
    let(:institution) { build(:school, establishment_type_code: 28, urn:, ukprn:) } # 28 is academy
    let(:course) { build(:course, :leading_literacy) }

    context "when only school is on PP50 list" do
      before do
        stub_const("PP50_SCHOOLS_URN_HASH", { "123" => true })
      end

      context "when school is chosen as work setting" do
        let(:work_setting) { Questionnaires::WorkSetting::A_SCHOOL }

        it_behaves_like "funding eligibility", funded: true, status_code: :funded, description: I18n.t("funding_details.scholarship_eligibility")
      end

      context "when FE is chosen as work setting" do
        let(:work_setting) { Questionnaires::WorkSetting::A_16_TO_19_EDUCATIONAL_SETTING }

        it_behaves_like "funding eligibility", funded: false, status_code: :ineligible_establishment_not_a_pp50, description: I18n.t("funding_details.not_a_pp50")
      end
    end

    context "when only FE is on PP50 list" do
      before do
        stub_const("PP50_FE_UKPRN_HASH", { "123" => true })
      end

      context "when FE is chosen as work setting" do
        let(:work_setting) { Questionnaires::WorkSetting::A_16_TO_19_EDUCATIONAL_SETTING }

        it_behaves_like "funding eligibility", funded: true, status_code: :funded, description: I18n.t("funding_details.scholarship_eligibility")
      end

      context "when school is chosen as work setting" do
        let(:work_setting) { Questionnaires::WorkSetting::A_SCHOOL }

        it_behaves_like "funding eligibility", funded: false, status_code: :ineligible_establishment_not_a_pp50, description: I18n.t("funding_details.not_a_pp50")
      end
    end
  end

  describe "#possible_funding_for_non_pp50_and_fe?" do
    subject { funding_eligibility.possible_funding_for_non_pp50_and_fe? }

    context "when course is pp50" do
      Course::ONLY_PP50.each do |identifier|
        let(:course) { Course.find_by(identifier: identifier) }

        context "when institution is a school" do
          let(:institution) { build(:school) }

          it { is_expected.to be true }
        end

        context "when institution is not a school" do
          let(:institution) { build(:local_authority) }

          it { is_expected.to be false }
        end
      end
    end

    context "when course is not pp50" do
      (Course::IDENTIFIERS - Course::ONLY_PP50).each do |identifier|
        let(:course) { Course.find_by(identifier: identifier) }
        let(:institution) { build(:school) }

        it { is_expected.to be false }
      end
    end
  end

  describe "#previously_received_targeted_funding_support?" do
    subject { funding_eligibility.previously_received_targeted_funding_support? }

    context "when the user has accepted applications" do
      let(:user) { build(:user, :with_get_an_identity_id, uid: get_an_identity_id) }
      let(:cohort) { build(:cohort, :current) }
      let(:targeted_delivery_funding_eligibility) { true }
      let(:funded_place) { false }

      before do
        create(:application, :accepted, user:, course:, cohort:, funded_place:, eligible_for_funding:, targeted_delivery_funding_eligibility:)
      end

      context "with eligible for funding" do
        let(:eligible_for_funding) { true }

        context "with funded place" do
          let(:funded_place) { true }

          context "with targeted_delivery_funding_eligibility" do
            let(:targeted_delivery_funding_eligibility) { true }

            it { is_expected.to be true }
          end

          context "without targeted_delivery_funding_eligibility" do
            let(:targeted_delivery_funding_eligibility) { false }

            it { is_expected.to be false }
          end
        end

        context "with funded place nil" do
          let(:cohort) { build(:cohort, start_year: 2023, funding_cap: false) }
          let(:funded_place) { nil }

          it { is_expected.to be true }
        end

        context "without funded place" do
          let(:funded_place) { false }

          it { is_expected.to be false }
        end
      end

      context "without eligible for funding" do
        let(:eligible_for_funding) { false }

        it { is_expected.to be false }
      end
    end

    context "when the user does not have accepted applications" do
      it { is_expected.to be false }
    end
  end
end
