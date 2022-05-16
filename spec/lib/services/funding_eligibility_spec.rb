require "rails_helper"

RSpec.describe Services::FundingEligibility do
  let(:institution) { school }
  let(:course) { Course.all.find { |c| !c.aso? } }
  let(:inside_catchment) { true }

  subject { described_class.new(institution: institution, course: course, inside_catchment: inside_catchment) }

  describe ".funded? && .funding_eligiblity_status_code" do
    context "in the special URN list" do
      let(:school) { build(:school, urn: "146816") }

      Course.all.each do |course|
        context "studying #{course.name}" do
          let(:course) { course }

          it "returns true" do
            expect(subject.funded?).to be_truthy
            expect(subject.funding_eligiblity_status_code).to eq :funded
          end
        end
      end
    end

    context "when institution is a School" do
      %w[1 2 3 5 6 7 8 12 14 15 18 24 26 28 31 32 33 34 35 36 38 39 40 41 42 43 44 45 46].each do |eligible_gias_code|
        context "eligible establishment_type_code #{eligible_gias_code}" do
          let(:school) { build(:school, establishment_type_code: eligible_gias_code) }

          it "returns true" do
            expect(subject.funded?).to be_truthy
            expect(subject.funding_eligiblity_status_code).to eq :funded
          end

          context "when undertaking ASO" do
            let(:course) { Course.all.find(&:aso?) }

            it "returns false" do
              expect(subject.funded?).to be_falsey
              expect(subject.funding_eligiblity_status_code).to eq :not_new_headteacher_requesting_aso
            end

            context "new headteacher" do
              subject do
                described_class.new(
                  institution: institution,
                  course: course,
                  inside_catchment: inside_catchment,
                  new_headteacher: true,
                )
              end

              it "returns true" do
                expect(subject.funded?).to be_truthy
                expect(subject.funding_eligiblity_status_code).to eq :funded
              end
            end
          end
        end
      end

      %w[10 11 25 27 29 30 37 56].each do |ineligible_gias_code|
        context "ineligible establishment_type_code #{ineligible_gias_code}" do
          let(:school) { build(:school, establishment_type_code: ineligible_gias_code) }

          it "returns false" do
            expect(subject.funded?).to be_falsey
            expect(subject.funding_eligiblity_status_code).to eq :ineligible_establishment_type
          end

          context "when undertaking ASO" do
            let(:course) { Course.all.find(&:aso?) }

            context "new headteacher" do
              subject do
                described_class.new(
                  institution: institution,
                  course: course,
                  inside_catchment: inside_catchment,
                  new_headteacher: true,
                )
              end

              it "returns false" do
                expect(subject.funded?).to be_falsey
                expect(subject.funding_eligiblity_status_code).to eq :ineligible_establishment_type
              end
            end

            context "not a new headteacher" do
              it "returns false" do
                expect(subject.funded?).to be_falsey
                expect(subject.funding_eligiblity_status_code).to eq :ineligible_establishment_type
              end
            end
          end
        end
      end
    end

    context "when institution is a LocalAuthority" do
      let(:institution) { create(:local_authority) }

      it "is eligible" do
        expect(subject.funded?).to be_truthy
        expect(subject.funding_eligiblity_status_code).to eq :funded
      end
    end
  end
end
