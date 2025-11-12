# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::ChangeCohort, type: :model do
  subject(:service) { described_class.new(application:, cohort_id:) }

  let(:application) { create(:application, cohort: cohort_2021) }
  let(:cohort_2021) { create(:cohort, start_year: 2021) }
  let(:new_cohort) { create(:cohort, start_year: 2025) }
  let(:cohort_id) { new_cohort.id }

  describe "validation" do
    it { is_expected.to validate_presence_of :application }
    it { is_expected.to validate_presence_of(:cohort_id).with_message "Choose a cohort" }

    context "when the new cohort start_year is different to the current cohort start year" do
      let(:cohort_id) { application.cohort.id }

      it { is_expected.not_to be_valid }
      it { is_expected.to have_error(:cohort_id, :must_be_different, "must be different") }
    end

    context "when the new cohort start_year is different" do
      let(:cohort_id) { new_cohort.id }

      it { is_expected.to be_valid }
    end

    context "when the application has declarations" do
      let(:application) { create(:application, :with_declaration, cohort: cohort_2021, schedule: create(:schedule, :npq_leadership_autumn, cohort: cohort_2021)) }

      before { create(:schedule, :npq_leadership_autumn, cohort: new_cohort) }

      it { is_expected.not_to be_valid }
      it { is_expected.to have_error(:cohort_id, :declarations_present, "Cannot change cohort for an application with declarations") }

      context "when override_declarations_check is true" do
        subject(:service) { described_class.new(application:, cohort_id:, override_declarations_check: true) }

        it { is_expected.to be_valid }
      end
    end

    context "when the application has a schedule" do
      let(:application) { create(:application, cohort: cohort_2021, schedule: create(:schedule, :npq_leadership_autumn, cohort: cohort_2021)) }

      context "when the new cohort has a schedule for the course group" do
        before { create(:schedule, :npq_leadership_autumn, cohort: new_cohort) }

        it { is_expected.to be_valid }
      end

      context "when the new cohort does not have a schedule for the course group" do
        it { is_expected.not_to be_valid }
        it { is_expected.to have_error(:cohort_id, :schedule_not_found, "There is no schedule for the current course in the specified cohort") }
      end
    end
  end

  describe "#change_cohort" do
    subject { service.change_cohort }

    context "when new cohort is the same as the current cohort" do
      let(:cohort_id) { application.cohort.id }

      it { is_expected.to be false }
    end

    context "when new cohort is different to the current cohort" do
      it "changes the cohort" do
        expect { subject }.to change(application, :cohort).to(new_cohort)
      end

      it { is_expected.to be true }
    end

    context "when the application is in a schedule" do
      let(:schedule) { create(:schedule, :npq_leadership_autumn, cohort: cohort_2021) }
      let(:application) { create(:application, cohort: cohort_2021, schedule: schedule) }
      let(:new_schedule) { create(:schedule, :npq_leadership_autumn, cohort: new_cohort) }

      context "when the new cohort has a schedule for the course group" do
        it "changes the schedule" do
          expect { subject }.to change(application, :schedule).to(new_schedule)
        end
      end
    end
  end

  describe "#cohort_options" do
    let(:cohort_2022) { create(:cohort, start_year: 2022) }
    let(:cohort_2023) { create(:cohort, start_year: 2023) }
    let(:cohort_2024) { create(:cohort, start_year: 2024) }
    let(:schedule_2021) { create(:schedule, :npq_leadership_autumn, cohort: cohort_2021) }

    before do
      create(:schedule, :npq_leadership_autumn, cohort: new_cohort)
      create(:schedule, :npq_leadership_autumn, cohort: cohort_2022)
      create(:schedule, :npq_leadership_spring, cohort: cohort_2022)
      create(:schedule, :npq_specialist_autumn, cohort: cohort_2022)
      create(:schedule, :npq_leadership_autumn, cohort: cohort_2023)
      create(:schedule, :npq_leadership_spring, cohort: cohort_2023)
      create(:schedule, :npq_specialist_autumn, cohort: cohort_2023)
      create(:schedule, :npq_specialist_autumn, cohort: cohort_2024)
    end

    context "when the application is in a schedule" do
      let(:application) { create(:application, cohort: cohort_2021, schedule: schedule_2021) }

      it "includes all cohorts with schedules for the course group excluding the application's current cohort" do
        expect(service.cohort_options).to contain_exactly(cohort_2022, cohort_2023, new_cohort)
      end
    end

    context "when the application is not in a schedule" do
      it "includes all cohorts except the application's current cohort" do
        expect(service.cohort_options).to eq [cohort_2022, cohort_2023, cohort_2024, new_cohort]
      end
    end
  end
end
