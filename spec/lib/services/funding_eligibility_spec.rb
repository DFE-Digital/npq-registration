require "rails_helper"

RSpec.describe Services::FundingEligibility do
  subject do
    described_class.new(institution:,
                        course:,
                        inside_catchment:,
                        trn:,
                        get_an_identity_id:,
                        approved_itt_provider:,
                        lead_mentor:)
  end

  let(:course) { Course.all.find { |c| !c.aso? } }
  let(:inside_catchment) { true }
  let(:trn) { "1234567" }
  let(:get_an_identity_id) { SecureRandom.uuid }
  let(:previously_funded) { false }
  let(:course_identifier) { course.identifier }
  let(:eyl_funding_eligible) { false }
  let(:approved_itt_provider) { nil }
  let(:lead_mentor) { nil }

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
      let(:institution) { build(:school, urn: "146816", eyl_funding_eligible:) }

      Course.all.each do |course|
        context "studying #{course.identifier}" do
          let(:course) { course }

          it "returns true" do
            expect(subject).to be_funded
            expect(subject.funding_eligiblity_status_code).to eq :funded
          end
        end
      end
    end

    context "when institution is a School" do
      %w[1 2 3 5 6 7 8 10 12 14 15 18 24 26 28 31 32 33 34 35 36 38 39 40 41 42 43 44 45 46].each do |eligible_gias_code|
        context "eligible establishment_type_code #{eligible_gias_code}" do
          let(:institution) { build(:school, establishment_type_code: eligible_gias_code, eyl_funding_eligible:) }

          it "returns true" do
            expect(subject).to be_funded
            expect(subject.funding_eligiblity_status_code).to eq :funded
          end

          context "when fundend in previous cohort" do
            let(:previously_funded) { true }

            it "is ineligible" do
              expect(subject.funded?).to be false
              expect(subject.funding_eligiblity_status_code).to eq :previously_funded
            end
          end

          context "when undertaking ASO" do
            let(:course) { Course.all.find(&:aso?) }

            it "returns false" do
              expect(subject).not_to be_funded
              expect(subject.funding_eligiblity_status_code).to eq :not_new_headteacher_requesting_aso
            end

            context "new headteacher" do
              subject do
                described_class.new(
                  institution:,
                  course:,
                  inside_catchment:,
                  new_headteacher: true,
                  get_an_identity_id:,
                  trn:,
                  approved_itt_provider:,
                  lead_mentor:,
                )
              end

              it "returns true" do
                expect(subject).to be_funded
                expect(subject.funding_eligiblity_status_code).to eq :funded
              end
            end
          end

          context "when school offering funding for the NPQEYL course" do
            let(:eyl_funding_eligible) { true }

            context "when user has selected the NPQEYL course" do
              let(:course) { Course.all.find(&:eyl?) }

              it "returns true" do
                expect(subject).to be_funded
              end
            end

            context "when user has not selected the NPQEYL course" do
              let(:course) { Course.all.find(&:npqsl?) }

              it "returns true" do
                expect(subject).to be_funded
              end
            end
          end
        end
      end

      %w[11 25 27 29 30 37 56].each do |ineligible_gias_code|
        context "ineligible establishment_type_code #{ineligible_gias_code}" do
          let(:institution) { build(:school, establishment_type_code: ineligible_gias_code, eyl_funding_eligible:) }

          it "returns false" do
            expect(subject).not_to be_funded
            expect(subject.funding_eligiblity_status_code).to eq :ineligible_establishment_type
          end

          context "when undertaking ASO" do
            let(:course) { Course.all.find(&:aso?) }

            context "new headteacher" do
              subject do
                described_class.new(
                  institution:,
                  course:,
                  inside_catchment:,
                  new_headteacher: true,
                  get_an_identity_id:,
                  trn:,
                  approved_itt_provider:,
                  lead_mentor:,
                )
              end

              it "returns false" do
                expect(subject).not_to be_funded
                expect(subject.funding_eligiblity_status_code).to eq :ineligible_establishment_type
              end
            end

            context "not a new headteacher" do
              it "returns false" do
                expect(subject).not_to be_funded
                expect(subject.funding_eligiblity_status_code).to eq :ineligible_establishment_type
              end
            end

            context "when school offering funding for the NPQEYL course" do
              let(:eyl_funding_eligible) { true }

              context "when user has selected the NPQEYL course" do
                let(:course) { Course.all.find(&:eyl?) }

                it "returns true" do
                  expect(subject).to be_funded
                end
              end

              context "when user has not selected the NPQEYL course" do
                let(:course) { Course.all.find(&:npqsl?) }

                it "returns false" do
                  expect(subject).not_to be_funded
                end
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
        let(:course) { Course.all.find(&:npqltd?) }

        it "is eligible" do
          expect(subject).to be_funded
          expect(subject.funding_eligiblity_status_code).to eq :funded
        end
      end

      context "and the course is not NPQLTD" do
        Course.all.reject(&:npqltd?).each do |course|
          let(:course) { course }

          it "is not eligible for #{course.name}" do
            expect(subject).not_to be_funded
            expect(subject.funding_eligiblity_status_code).to eq :not_lead_mentor_course
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

      context "when funded in previous cohort" do
        let(:previously_funded) { true }

        it "is ineligible" do
          expect(subject.funded?).to be false
          expect(subject.funding_eligiblity_status_code).to eq :previously_funded
        end
      end
    end

    context "when institution is a PrivateChildcareProvider" do
      context "when meets all the funding criteria" do
        let(:institution) { build(:private_childcare_provider, :on_early_years_register) }
        let(:course) { Course.all.find(&:eyl?) }
        let(:inside_catchment) { true }

        it "is eligible" do
          expect(subject).to be_funded
          expect(subject.funding_eligiblity_status_code).to eq :funded
        end
      end

      context "when does not meets all the funding criteria" do
        let(:institution) { build(:private_childcare_provider, :on_early_years_register) }
        let(:course) { Course.all.find(&:eyl?) }
        let(:inside_catchment) { true }

        context "when fundend in previous cohort" do
          let(:previously_funded) { true }

          it "is ineligible" do
            expect(subject.funded?).to be false
            expect(subject.funding_eligiblity_status_code).to eq :previously_funded
          end
        end

        context "when outside catchment" do
          let(:inside_catchment) { false }

          it "returns status code :early_years_outside_catchment" do
            expect(subject.funding_eligiblity_status_code).to eq :early_years_outside_catchment
          end

          it "is not eligible" do
            expect(subject.funded?).to be false
          end
        end

        context "when NPQ course is not Early Year Leadership" do
          let(:course) { Course.all.find { |c| !c.eyl? } }

          it "returns status code :early_years_invalid_npq" do
            expect(subject.funding_eligiblity_status_code).to eq :early_years_invalid_npq
          end

          it "is not eligible" do
            expect(subject.funded?).to be false
          end
        end

        context "when institution is not on early years register" do
          let(:institution) { build(:private_childcare_provider, early_years_individual_registers: []) }

          it "returns status code :not_on_early_years_register" do
            expect(subject.funding_eligiblity_status_code).to eq :not_on_early_years_register
          end

          it "is not eligible" do
            expect(subject.funded?).to be false
          end
        end
      end
    end
  end
end
