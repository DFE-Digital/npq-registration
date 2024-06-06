require "rails_helper"

RSpec.describe CourseGroup, type: :model do
  let(:cohort) { create(:cohort, :current) }

  subject { build(:course_group) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name).with_message("Enter a unique course group name") }
    it { is_expected.to validate_uniqueness_of(:name).with_message("Course name already exist, enter a unique name") }
  end

  describe "associations" do
    it { is_expected.to have_many(:courses) }
  end

  describe "#schedule_for" do
    let(:schedule_date) { Date.current }

    context "when NPQ Leadership" do
      subject { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }

      let!(:autumn_schedule) { create(:schedule, :npq_leadership_autumn, course_group: subject, cohort:) }
      let!(:spring_schedule) { create(:schedule, :npq_leadership_spring, course_group: subject, cohort:) }

      context "when date is between June and December of cohort start year" do
        it "returns Autumn schedule" do
          travel_to Date.new(cohort.start_year, 6, 1) do
            expect(subject.schedule_for(cohort:)).to eq(autumn_schedule)
          end
        end
      end

      context "when date is between December of cohort start year and April of the next year" do
        it "returns Spring schedule" do
          travel_to Date.new(cohort.start_year, 12, 26) do
            expect(subject.schedule_for(cohort:)).to eq(spring_schedule)
          end
        end
      end

      context "when date is between April and December of the next year" do
        it "returns Autumn schedule" do
          travel_to Date.new(cohort.start_year + 1, 4, 3) do
            expect(subject.schedule_for(cohort:)).to eq(autumn_schedule)
          end
        end
      end

      context "when date is between December of next year and April in 2 years" do
        it "returns Spring schedule" do
          travel_to Date.new(cohort.start_year + 1, 12, 26) do
            expect(subject.schedule_for(cohort:)).to eq(spring_schedule)
          end
        end
      end
    end

    context "when NPQ Specialist" do
      subject { CourseGroup.find_by(name: "specialist") || create(:course_group, name: "specialist") }

      let!(:autumn_schedule) { create(:schedule, :npq_specialist_autumn, course_group: subject, cohort:) }
      let!(:spring_schedule) { create(:schedule, :npq_specialist_spring, course_group: subject, cohort:) }

      context "when date is between June and December of cohort start year" do
        it "returns Autumn schedule" do
          travel_to Date.new(cohort.start_year, 6, 1) do
            expect(subject.schedule_for(cohort:)).to eq(autumn_schedule)
          end
        end
      end

      context "when date is between December of cohort start year and April of the next year" do
        it "returns Spring schedule" do
          travel_to Date.new(cohort.start_year, 12, 26) do
            expect(subject.schedule_for(cohort:)).to eq(spring_schedule)
          end
        end
      end

      context "when date is between April and December of the next year" do
        it "returns Autumn schedule" do
          travel_to Date.new(cohort.start_year + 1, 4, 3) do
            expect(subject.schedule_for(cohort:)).to eq(autumn_schedule)
          end
        end
      end

      context "when date is between December of next year and April in 2 years" do
        it "returns Spring schedule" do
          travel_to Date.new(cohort.start_year + 1, 12, 26) do
            expect(subject.schedule_for(cohort:)).to eq(spring_schedule)
          end
        end
      end
    end

    context "when NPQ Support" do
      subject { CourseGroup.find_by(name: "support") || create(:course_group, name: "support") }

      let!(:schedule) { create(:schedule, :npq_aso_december, course_group: subject, cohort:) }

      it "returns NPQ ASO December schedule" do
        expect(subject.schedule_for(cohort:)).to eql(schedule)
      end
    end

    context "when NPQ Ehco" do
      subject { CourseGroup.find_by(name: "ehco") || create(:course_group, name: "ehco") }

      let!(:november_schedule) { create(:schedule, :npq_ehco_november, course_group: subject, cohort:) }
      let!(:december_schedule) { create(:schedule, :npq_ehco_december, course_group: subject, cohort:) }
      let!(:march_schedule) { create(:schedule, :npq_ehco_march, course_group: subject, cohort:) }
      let!(:june_schedule) { create(:schedule, :npq_ehco_june, course_group: subject, cohort:) }

      context "when date is between September and November of cohort start year" do
        it "returns NPQ EHCO November schedule" do
          travel_to Date.new(cohort.start_year, 9, 1) do
            expect(subject.schedule_for(cohort:)).to eq(november_schedule)
          end
        end
      end

      context "when date is between December of cohort start year and February of the next year" do
        it "returns NPQ EHCO December schedule" do
          travel_to Date.new(cohort.start_year, 12, 1) do
            expect(subject.schedule_for(cohort:)).to eq(december_schedule)
          end
        end
      end

      context "when date is between March and May of the next year" do
        it "returns NPQ EHCO March schedule" do
          travel_to Date.new(cohort.start_year + 1, 3, 1) do
            expect(subject.schedule_for(cohort:)).to eq(march_schedule)
          end
        end
      end

      context "when date is between June and September of the next year" do
        it "returns NPQ EHCO June schedule" do
          travel_to Date.new(cohort.start_year + 1, 6, 1) do
            expect(subject.schedule_for(cohort:)).to eq(june_schedule)
          end
        end
      end

      context "when date range exceeds the current cohort" do
        it "returns default schedule for cohort" do
          travel_to Date.new(cohort.start_year + 1, 10, 1) do
            expect(subject.schedule_for(cohort:)).to eq(june_schedule)
          end
        end
      end

      context "when selected cohort is before multiple schedules existed for EHCO" do
        let(:cohort_2021) { create(:cohort, start_year: 2021) }
        let!(:june_schedule_2021) { create(:schedule, :npq_ehco_june, course_group: subject, cohort: cohort_2021) }

        it "returns NPQ EHCO June schedule" do
          expect(subject.schedule_for(cohort: cohort_2021)).to eq(june_schedule_2021)
        end
      end
    end
  end

  describe "#autumn_schedule_2022?" do
    it "returns true when date between Jun 1 to Dec 25 in 2022" do
      (("2022-06-1".to_date)..("2022-12-25".to_date)).each do |date|
        expect(subject.autumn_schedule_2022?(date)).to be(true)
      end
    end

    it "returns false when date between Dec 26 to May 31" do
      (2022..Date.current.year).each do |year|
        (("#{year}-12-26".to_date)..("#{year + 1}-05-31".to_date)).each do |date|
          expect(subject.autumn_schedule_2022?(date)).to be(false)
        end
      end
    end
  end

  describe "#spring_schedule?" do
    it "returns true when date between Dec 26 to Apr 2" do
      (2.years.ago.year..Date.current.year).each do |year|
        (("#{year}-12-26".to_date)..("#{year + 1}-04-2".to_date)).each do |date|
          expect(subject.spring_schedule?(date)).to be(true)
        end
      end
    end

    it "returns false when date between Apr 3 to Dec 25" do
      (2.years.ago.year..Date.current.year).each do |year|
        (("#{year}-04-3".to_date)..("#{year}-12-25".to_date)).each do |date|
          expect(subject.spring_schedule?(date)).to be(false)
        end
      end
    end
  end

  describe "#autumn_schedule?" do
    it "returns true when date between Apr 3 to Dec 25" do
      (2.years.ago.year..Date.current.year).each do |year|
        (("#{year}-04-3".to_date)..("#{year}-12-25".to_date)).each do |date|
          expect(subject.autumn_schedule?(date)).to be(true)
        end
      end
    end

    it "returns false when date between Dec 26 to Apr 2" do
      (2.years.ago.year..Date.current.year).each do |year|
        (("#{year}-12-26".to_date)..("#{year + 1}-04-2".to_date)).each do |date|
          expect(subject.autumn_schedule?(date)).to be(false)
        end
      end
    end
  end
end
