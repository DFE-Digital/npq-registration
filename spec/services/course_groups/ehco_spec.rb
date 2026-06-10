require "rails_helper"

RSpec.describe CourseGroups::Ehco do
  let(:cohort) { create(:cohort, :current) }
  let(:schedule_date) { Date.current }
  let(:course_group) { CourseGroup.find_by(name: "ehco") || create(:course_group, name: "ehco") }

  subject { described_class.new(course_group:, cohort:, schedule_date:) }

  describe "#schedule" do
    before { schedules }

    let :schedules do
      {
        november: create(:schedule, :npq_ehco_november, course_group:, cohort:),
        december: create(:schedule, :npq_ehco_december, course_group:, cohort:),
        march: create(:schedule, :npq_ehco_march, course_group:, cohort:),
        june: create(:schedule, :npq_ehco_june, course_group:, cohort:),
      }
    end

    context "when date is between September and November of cohort start year" do
      it "returns NPQ EHCO November schedule" do
        travel_to Date.new(cohort.start_year, 9, 1) do
          expect(subject.schedule).to eq(schedules[:november])
        end
      end
    end

    context "when date is between December of cohort start year and February of the next year" do
      it "returns NPQ EHCO December schedule" do
        travel_to Date.new(cohort.start_year, 12, 1) do
          expect(subject.schedule).to eq(schedules[:december])
        end
      end
    end

    context "when date is between March and May of the next year" do
      it "returns NPQ EHCO March schedule" do
        travel_to Date.new(cohort.start_year + 1, 3, 1) do
          expect(subject.schedule).to eq(schedules[:march])
        end
      end
    end

    context "when date is between June and September of the next year" do
      it "returns NPQ EHCO June schedule" do
        travel_to Date.new(cohort.start_year + 1, 6, 1) do
          expect(subject.schedule).to eq(schedules[:june])
        end
      end
    end

    context "when date range exceeds the current cohort" do
      it "returns default schedule for cohort" do
        travel_to Date.new(cohort.start_year + 1, 10, 1) do
          expect(subject.schedule).to eq(schedules[:june])
        end
      end
    end

    context "when selected cohort is before multiple schedules existed for EHCO" do
      let(:cohort_2021) { create(:cohort, start_year: 2021) }
      let!(:june_schedule_2021) { create(:schedule, :npq_ehco_june, course_group:, cohort: cohort_2021) }

      subject { described_class.new(course_group:, cohort: cohort_2021, schedule_date:) }

      it "returns NPQ EHCO June schedule" do
        expect(subject.schedule).to eq(june_schedule_2021)
      end
    end

    context "when selected cohort is non-scholarship funded 2026 spring cohort" do
      let(:cohort) { create(:cohort, start_year: 2026, suffix: "a") }

      let :schedules do
        {
          march: create(:schedule, :npq_ehco_march, course_group:, cohort:),
        }
      end

      it "returns NPQ EHCO March schedule" do
        expect(subject.schedule).to eq(schedules[:march])
      end
    end
  end
end
