require "rails_helper"

RSpec.describe CourseGroups::Leadership do
  let(:cohort) { create(:cohort, :current) }
  let(:schedule_date) { Date.current }
  let(:course_group) { CourseGroup.find_by(name: "leadership") || create(:course_group, name: "leadership") }
  let(:course_group_name) { "leadership" }
  let(:spring_schedule_identifier) { "npq_leadership_spring" }
  let(:autumn_schedule_identifier) { "npq_leadership_autumn" }

  subject { described_class.new(course_group:, cohort:, schedule_date:) }

  it_behaves_like "leadership and specialist #schedule"

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
