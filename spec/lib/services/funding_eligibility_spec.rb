require "rails_helper"

RSpec.describe Services::FundingEligibility do
  subject { described_class.new(course: course, school: school) }

  describe "#call" do
    context "studying for NPQEL, NPQLBC, NPQSL, NPQLT" do
      let(:course) { Course.all.select { |c| c.name.match?(/\(NPQEL\)|\(NPQLBC\)|\(NPQSL\)|\(NPQLT\)/) }.sample }

      context "eligible establishment" do
        let(:eligible_gias_code) { %w[1 2 3 5 6 7 8 12 14 28 33 34 35 36 38 40 41 42 43 44].sample }
        let(:school) { build(:school, establishment_type_code: eligible_gias_code) }

        context "high pupil premium" do
          before do
            school.high_pupil_premium = true
          end

          it "returns true" do
            expect(subject.call).to be_truthy
          end
        end

        context "low pupil premium" do
          before do
            school.high_pupil_premium = false
          end

          it "returns false" do
            expect(subject.call).to be_falsey
          end
        end
      end

      context "ineligible establishment" do
        let(:ineligible_gias_code) { %w[10 11 15 18 24 25 26 27 29 30 31 32 37 39 45 46 56].sample }
        let(:school) { build(:school, establishment_type_code: ineligible_gias_code) }

        context "high pupil premium" do
          before do
            school.high_pupil_premium = true
          end

          it "returns false" do
            expect(subject.call).to be_falsey
          end
        end

        context "low pupil premium" do
          before do
            school.high_pupil_premium = false
          end

          it "returns false" do
            expect(subject.call).to be_falsey
          end
        end
      end
    end

    context "studying for NPQLTD or NPQH" do
      let(:course) { Course.all.select { |c| c.name.match?(/\(NPQLTD\)|\(NPQH\)/) }.sample }

      context "eligible establishment" do
        let(:eligible_gias_code) { %w[1 2 3 5 6 7 8 12 14 15 28 33 34 35 36 38 39 40 41 42 44 45].sample }
        let(:school) { build(:school, establishment_type_code: eligible_gias_code) }

        it "returns true" do
          expect(subject.call).to be_truthy
        end
      end

      context "ineligible establishment" do
        let(:ineligible_gias_code) { %w[10 11 18 24 25 26 27 29 30 31 32 37 43 46 56].sample }
        let(:school) { build(:school, establishment_type_code: ineligible_gias_code) }

        it "returns false" do
          expect(subject.call).to be_falsey
        end
      end
    end
  end
end
