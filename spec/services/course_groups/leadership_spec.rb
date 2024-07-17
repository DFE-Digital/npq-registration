require "rails_helper"

RSpec.describe CourseGroups::Leadership do
  let(:cohort) { create(:cohort, :current) }
  let(:schedule_date) { Date.current }
  let(:course_group) { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }

  subject { described_class.new(course_group:, cohort:, schedule_date:) }

  describe "#schedule" do
    let!(:autumn_schedule) { create(:schedule, :npq_leadership_autumn, course_group:, cohort:) }
    let!(:spring_schedule) { create(:schedule, :npq_leadership_spring, course_group:, cohort:) }

    context "when date is between June and December of cohort start year" do
      it "returns Autumn schedule" do
        travel_to Date.new(cohort.start_year, 6, 1) do
          expect(subject.schedule).to eq(autumn_schedule)
        end
      end
    end

    context "when date is between December of cohort start year and April of the next year" do
      it "returns Spring schedule" do
        travel_to Date.new(cohort.start_year, 12, 26) do
          expect(subject.schedule).to eq(spring_schedule)
        end
      end
    end

    context "when date is between April and December of the next year" do
      it "returns Autumn schedule" do
        travel_to Date.new(cohort.start_year + 1, 4, 3) do
          expect(subject.schedule).to eq(autumn_schedule)
        end
      end
    end

    context "when date is between December of next year and April in 2 years" do
      it "returns Spring schedule" do
        travel_to Date.new(cohort.start_year + 1, 12, 26) do
          expect(subject.schedule).to eq(spring_schedule)
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
