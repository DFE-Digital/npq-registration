# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "leadership and specialist #schedule" do
  let(:course_group) { CourseGroup.find_by(name: course_group_name) }

  subject { described_class.new(course_group:, cohort:, schedule_date: Date.current).schedule }

  before { travel_to(date) }

  let(:date) { Date.new(2025, 6, 1) }

  context "when the course is only in the spring schedule (like the 2025 cohort)" do
    let!(:spring_schedule) { create(:schedule, spring_schedule_identifier, course_group:, cohort:) }
    let(:cohort) { create(:cohort, start_year: 2025) }

    it { is_expected.to eq(spring_schedule) }
  end

  context "when the course is only in the autumn schedule (like the 2024 cohort)" do
    let!(:autumn_schedule) { create(:schedule, autumn_schedule_identifier, course_group:, cohort:) }
    let(:cohort) { create(:cohort, start_year: 2024) }

    it { is_expected.to eq(autumn_schedule) }
  end

  context "when course is in both autumn and spring schedules (like 2021-2023 cohorts)" do
    let!(:spring_schedule) { create(:schedule, spring_schedule_identifier, course_group:, cohort:) }
    let!(:autumn_schedule) { create(:schedule, autumn_schedule_identifier, course_group:, cohort:) }
    let(:cohort) { create(:cohort, start_year: 2023) }

    context "when date is between 1st January and 2nd April" do
      before { travel_to(Date.new(2025, 4, 2)) }

      it { is_expected.to eq(spring_schedule) }
    end

    context "when date is between 26th December and 31st December" do
      before { travel_to(Date.new(2025, 12, 31)) }

      it { is_expected.to eq(spring_schedule) }
    end

    context "when date is between 3rd April and 25th December" do
      before { travel_to(Date.new(2025, 12, 25)) }

      it { is_expected.to eq(autumn_schedule) }
    end
  end
end
