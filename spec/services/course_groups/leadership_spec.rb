require "rails_helper"

RSpec.describe CourseGroups::Leadership do
  let(:cohort) { create(:cohort, :current) }
  let(:schedule_date) { Date.current }
  let(:course_group) { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }

  subject { described_class.new(course_group:, cohort:, schedule_date:) }

  describe "#schedule" do
    let!(:autumn_schedule) { create(:schedule, :npq_leadership_autumn, course_group:, cohort:) }
    let!(:spring_schedule) { create(:schedule, :npq_leadership_spring, course_group:, cohort:) }

    subject(:schedule) { described_class.new(course_group:, cohort:, schedule_date:).schedule }

    context "when date is between June and December of cohort start year" do
      before { travel_to Date.new(cohort.start_year, 6, 1) }

      it { is_expected.to eq(autumn_schedule) }
    end

    context "when date is between December of cohort start year and April of the following year" do
      let(:cohort) { create(:cohort, start_year: 2025) }

      before { travel_to Date.new(cohort.start_year, 12, 26) }

      it { is_expected.to eq(spring_schedule) }
    end

    context "when date is between April and December of the next year" do
      before { travel_to Date.new(cohort.start_year + 1, 4, 3) }

      it { is_expected.to eq(autumn_schedule) }
    end

    context "when date is between December of next year and April in 2 years" do
      before { travel_to Date.new(cohort.start_year + 1, 12, 26) }

      it { is_expected.to eq(spring_schedule) }
    end

    context "when date is spring 2025" do
      let(:cohort) { create(:cohort, start_year: 2024) }

      before { travel_to Date.new(2025, 1, 13) }

      it { is_expected.to eq(autumn_schedule) }
    end
  end

  describe "#autumn_schedule_2022?" do
    it "returns true when date between 1st Jun 2022 and 25th Dec 2022" do
      (("2022-06-1".to_date)..("2022-12-25".to_date)).each do |date|
        expect(subject.autumn_schedule_2022?(date)).to be(true)
      end
    end

    it "returns false when date between 26th Dec and 31st May" do
      (2022..Date.current.year).each do |year|
        (("#{year}-12-26".to_date)..("#{year + 1}-05-31".to_date)).each do |date|
          expect(subject.autumn_schedule_2022?(date)).to be(false)
        end
      end
    end
  end

  describe "#autumn_schedule_2024?" do
    it "returns true when date between 28th Jun 2024 and 6th June 2025" do
      (("2024-06-28".to_date)..("2025-06-06".to_date)).each do |date|
        expect(subject.autumn_schedule_2024?(date)).to be(true)
      end
    end

    it "returns false when before 28th Jun 2024" do
      (("2022-01-01".to_date)..("2024-06-27".to_date)).each do |date|
        expect(subject.autumn_schedule_2024?(date)).to be(false)
      end
    end

    it "returns false when after 6th June 2025" do
      (("2025-06-07".to_date)..(Date.current.end_of_year)).each do |date|
        expect(subject.autumn_schedule_2024?(date)).to be(false)
      end
    end
  end

  describe "#spring_schedule?" do
    it "returns true when date between 26th Dec and 2nd Apr" do
      (2.years.ago.year..Date.current.year).each do |year|
        (("#{year}-12-26".to_date)..("#{year + 1}-04-2".to_date)).each do |date|
          expect(subject.spring_schedule?(date)).to be(true)
        end
      end
    end

    it "returns false when date between 3rd Apr and 25th Dec" do
      (2.years.ago.year..Date.current.year).each do |year|
        (("#{year}-04-3".to_date)..("#{year}-12-25".to_date)).each do |date|
          expect(subject.spring_schedule?(date)).to be(false)
        end
      end
    end
  end

  describe "#autumn_schedule?" do
    it "returns true when date between 3rd Apr and 25th Dec" do
      (2.years.ago.year..Date.current.year).each do |year|
        (("#{year}-04-3".to_date)..("#{year}-12-25".to_date)).each do |date|
          expect(subject.autumn_schedule?(date)).to be(true)
        end
      end
    end

    it "returns false when date between 26th Dec and 2nd Apr" do
      (2.years.ago.year..Date.current.year).each do |year|
        (("#{year}-12-26".to_date)..("#{year + 1}-04-2".to_date)).each do |date|
          expect(subject.autumn_schedule?(date)).to be(false)
        end
      end
    end
  end
end
