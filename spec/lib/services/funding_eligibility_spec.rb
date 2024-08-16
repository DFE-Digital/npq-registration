require "rails_helper"

RSpec.describe FundingEligibility do
  subject do
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

  let(:course) { create(:course, :additional_support_offer) }
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
  let(:query_store) { nil }

  before do
    mock_previous_funding_api_request(
      course_identifier:,
      get_an_identity_id:,
      trn:,
      response: ecf_funding_lookup_response(previously_funded:),
    )
  end

  describe ".funded? && .funding_eligiblity_status_code" do
    context "in the special URN list" do
      let(:institution) { create(:school, :funding_eligible_establishment_type_code, urn: "100000") }

      Course.all.find_each do |course|
        context "studying #{course.identifier}" do
          let(:course) { course }

          it "returns true" do
            expect(subject).to be_funded
            expect(subject.funding_eligiblity_status_code).to eq :funded
          end

          context "when External::EcfAPI is disabled" do
            before { allow(Rails.application.config).to receive(:npq_separation).and_return({ ecf_api_disabled: true }) }

            it "returns true" do
              expect(subject).to be_funded
              expect(subject.funding_eligiblity_status_code).to eq :funded
            end
          end
        end
      end
    end

    context "when institution is a School" do
      %w[1 2 3 5 6 7 8 10 12 14 15 18 24 26 28 31 32 33 34 35 36 38 39 40 41 42 43 44 45 46].each do |eligible_gias_code|
        context "eligible establishment_type_code #{eligible_gias_code}" do
          let(:institution) { build(:school, establishment_type_code: eligible_gias_code, urn:) }
          let(:course) { create(:course, :headship) }
          let(:urn) { "123" }

          it "returns true" do
            expect(subject).to be_funded
            expect(subject.funding_eligiblity_status_code).to eq :funded
          end

          context "when previously funded" do
            let(:previously_funded) { true }

            it "is ineligible" do
              expect(subject.funded?).to be false
              expect(subject.funding_eligiblity_status_code).to eq :previously_funded
            end

            context "when External::EcfAPI is disabled" do
              before do
                allow(Rails.application.config).to receive(:npq_separation).and_return({ ecf_api_disabled: true })
                user = create(:user, trn:)
                create(:application, :previously_funded, user:, course:)
              end

              it "is ineligible" do
                expect(subject.funded?).to be false
                expect(subject.funding_eligiblity_status_code).to eq :previously_funded
              end
            end
          end

          context "when school offering funding for the NPQEYL course" do
            context "and school is on the eligible list" do
              let(:urn) { eligible_ey_urn }

              context "when user has selected the NPQEYL course" do
                let(:course) { create(:course, :early_years_leadership) }

                it "returns true" do
                  expect(subject).to be_funded
                end
              end
            end

            context "when user has selected the NPQEYL course" do
              let(:course) { create(:course, :early_years_leadership) }

              it "returns false" do
                expect(subject).not_to be_funded
              end
            end

            context "when user has not selected the NPQEYL course" do
              let(:course) { create(:course, :headship) }

              it "returns true" do
                expect(subject).to be_funded
              end
            end
          end

          context "when External::EcfAPI is disabled" do
            before { allow(Rails.application.config).to receive(:npq_separation).and_return({ ecf_api_disabled: true }) }

            it "returns true" do
              expect(subject).to be_funded
              expect(subject.funding_eligiblity_status_code).to eq :funded
            end
          end
        end
      end

      %w[11 25 27 29 30 37 56].each do |ineligible_gias_code|
        context "ineligible establishment_type_code #{ineligible_gias_code}" do
          let(:institution) { build(:school, establishment_type_code: ineligible_gias_code, urn:) }
          let(:urn) { "123" }

          it "returns false" do
            expect(subject).not_to be_funded
            expect(subject.funding_eligiblity_status_code).to eq :ineligible_establishment_type
          end

          context "when school offering funding for the NPQEYL course" do
            let(:urn) { eligible_ey_urn }

            context "when user has selected the NPQEYL course" do
              let(:course) { create(:course, :early_years_leadership) }

              it "returns true" do
                expect(subject).to be_funded
              end
            end

            context "when user has not selected the NPQEYL course" do
              let(:course) { create(:course, :additional_support_offer) }

              it "returns false" do
                expect(subject).not_to be_funded
              end
            end
          end

          context "when External::EcfAPI is disabled" do
            before { allow(Rails.application.config).to receive(:npq_separation).and_return({ ecf_api_disabled: true }) }

            it "returns false" do
              expect(subject).not_to be_funded
              expect(subject.funding_eligiblity_status_code).to eq :ineligible_establishment_type
            end
          end
        end
      end

      context "when school is LA nursery" do
        let(:institution) { build(:school, establishment_type_code: "15") }

        context "when LA disadvantaged nursery" do
          before do
            allow(institution).to receive(:la_disadvantaged_nursery?).and_return(true)
          end

          {
            senco: true,
            leading_primary_mathmatics: true,
            headship: true,
            senior_leadership: true,
            leading_literacy: true,
          }.each do |course, eligible|
            context "when user has selected the #{course} course" do
              let(:course) { create(:course, course) }

              it "returns #{eligible}" do
                expect(subject.funded?).to eq eligible
              end
            end
          end
        end

        context "when not LA disadvantaged nursery" do
          before do
            allow(institution).to receive(:la_disadvantaged_nursery?).and_return(false)
          end

          {
            senco: true,
            leading_primary_mathmatics: true,
            headship: true,
            senior_leadership: false,
            leading_literacy: false,
          }.each do |course, eligible|
            context "when user has selected the #{course} course" do
              let(:course) { create(:course, course) }

              it "returns #{eligible}" do
                expect(subject.funded?).to eq eligible
              end
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
        let(:course) { create(:course, :leading_teaching_development) }

        it "is eligible" do
          expect(subject).to be_funded
          expect(subject.funding_eligiblity_status_code).to eq :funded
        end

        context "when External::EcfAPI is disabled" do
          before { allow(Rails.application.config).to receive(:npq_separation).and_return({ ecf_api_disabled: true }) }

          it "is eligible" do
            expect(subject).to be_funded
            expect(subject.funding_eligiblity_status_code).to eq :funded
          end
        end
      end

      context "and the course is not NPQLTD or NPQS" do
        Course.all.reject { |c| c.npqltd? || c.npqs? }.each do |course|
          let(:course) { course }

          it "is not eligible for #{course.identifier}" do
            expect(subject).not_to be_funded
            expect(subject.funding_eligiblity_status_code).to eq :not_lead_mentor_course
          end

          context "when External::EcfAPI is disabled" do
            before { allow(Rails.application.config).to receive(:npq_separation).and_return({ ecf_api_disabled: true }) }

            it "is not eligible for #{course.identifier}" do
              expect(subject).not_to be_funded
              expect(subject.funding_eligiblity_status_code).to eq :not_lead_mentor_course
            end
          end
        end
      end
    end

    context "when institution is a LocalAuthority" do
      let(:institution) { create(:local_authority) }

      it "is eligible" do
        expect(subject).to be_funded
        expect(subject.funding_eligiblity_status_code).to eq :funded
      end

      context "when External::EcfAPI is disabled" do
        before { allow(Rails.application.config).to receive(:npq_separation).and_return({ ecf_api_disabled: true }) }

        it "is eligible" do
          expect(subject).to be_funded
          expect(subject.funding_eligiblity_status_code).to eq :funded
        end
      end

      context "when previously funded" do
        let(:previously_funded) { true }

        it "is ineligible" do
          expect(subject.funded?).to be false
          expect(subject.funding_eligiblity_status_code).to eq :previously_funded
        end

        context "when External::EcfAPI is disabled" do
          before do
            allow(Rails.application.config).to receive(:npq_separation).and_return({ ecf_api_disabled: true })
            user = create(:user, trn:)
            create(:application, :previously_funded, user:, course:)
          end

          it "is ineligible" do
            expect(subject.funded?).to be false
            expect(subject.funding_eligiblity_status_code).to eq :previously_funded
          end
        end
      end
    end

    context "when institution is a PrivateChildcareProvider" do
      context "when does not meets all the funding criteria" do
        let(:institution) { build(:private_childcare_provider, :on_early_years_register) }
        let(:course) { create(:course, :early_years_leadership) }
        let(:inside_catchment) { true }

        context "when previously funded" do
          let(:previously_funded) { true }

          it "is ineligible" do
            expect(subject.funded?).to be false
            expect(subject.funding_eligiblity_status_code).to eq :previously_funded
          end

          context "when External::EcfAPI is disabled" do
            before do
              allow(Rails.application.config).to receive(:npq_separation).and_return({ ecf_api_disabled: true })
              user = create(:user, trn:)
              create(:application, :previously_funded, user:, course:)
            end

            it "is ineligible" do
              expect(subject.funded?).to be false
              expect(subject.funding_eligiblity_status_code).to eq :previously_funded
            end
          end
        end

        context "when outside catchment" do
          let(:inside_catchment) { false }

          it "returns status code :not_in_england" do
            expect(subject.funding_eligiblity_status_code).to eq :not_in_england
          end

          it "is not eligible" do
            expect(subject.funded?).to be false
          end

          context "when External::EcfAPI is disabled" do
            before { allow(Rails.application.config).to receive(:npq_separation).and_return({ ecf_api_disabled: true }) }

            it "returns status code :not_in_england" do
              expect(subject.funding_eligiblity_status_code).to eq :not_in_england
            end

            it "is not eligible" do
              expect(subject.funded?).to be false
            end
          end
        end

        context "when NPQ course is not Early Year Leadership" do
          let(:course) { create(:course, :additional_support_offer) }

          it "returns status code :early_years_invalid_npq" do
            expect(subject.funding_eligiblity_status_code).to eq :early_years_invalid_npq
          end

          it "is not eligible" do
            expect(subject.funded?).to be false
          end

          context "when External::EcfAPI is disabled" do
            before { allow(Rails.application.config).to receive(:npq_separation).and_return({ ecf_api_disabled: true }) }

            it "returns status code :early_years_invalid_npq" do
              expect(subject.funding_eligiblity_status_code).to eq :early_years_invalid_npq
            end

            it "is not eligible" do
              expect(subject.funded?).to be false
            end
          end
        end

        context "when institution is not on early years register" do
          let(:institution) { build(:private_childcare_provider, provider_urn: "100000", early_years_individual_registers: []) }
          let(:query_store) { instance_double(RegistrationQueryStore, childminder?: false) }

          it "is not eligible" do
            expect(subject.funded?).to be false
            expect(subject.funding_eligiblity_status_code).to eq :not_entitled_ey_institution
          end

          context "when External::EcfAPI is disabled" do
            before { allow(Rails.application.config).to receive(:npq_separation).and_return({ ecf_api_disabled: true }) }

            it "is not eligible" do
              expect(subject.funded?).to be false
              expect(subject.funding_eligiblity_status_code).to eq :not_entitled_ey_institution
            end
          end
        end
      end
    end

    context "when user is referred by return to teaching adviser" do
      let(:institution) { nil }
      let(:inside_catchment) { true }
      let(:query_store) { instance_double(RegistrationQueryStore, referred_by_return_to_teaching_adviser?: true) }

      it "is ineligible" do
        expect(subject.funded?).to be false
        expect(subject.funding_eligiblity_status_code).to eq :referred_by_return_to_teaching_adviser
      end

      context "when External::EcfAPI is disabled" do
        before { allow(Rails.application.config).to receive(:npq_separation).and_return({ ecf_api_disabled: true }) }

        it "is ineligible" do
          expect(subject.funded?).to be false
          expect(subject.funding_eligiblity_status_code).to eq :referred_by_return_to_teaching_adviser
        end
      end
    end
  end
end
