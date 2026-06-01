require "rails_helper"

RSpec.describe "sandbox test data for 2026 tasks" do
  subject :run_task do
    Rake::Task["one_off:sandbox_test_data_2026"].invoke(dry_run)
  end

  before { cohorts && schedules }

  after do
    Rake::Task["one_off:sandbox_test_data_2026"].reenable
  end

  let(:dry_run) { "false" }

  let :cohorts do
    {
      twentythree: create(:cohort, start_year: 2023),
      spring: create(:cohort, start_year: 2026, suffix: "a", funding: :zero),
      autumn: create(:cohort, start_year: 2026, suffix: "b", funding: :capped),
    }
  end

  let(:schedules) { [create(:schedule, :npq_leadership_autumn, cohort: cohorts[:autumn])] }

  context "when performing a dry run" do
    let(:dry_run) { nil }

    it "leaves data unchanged" do
      expect { run_task }
        .to not_change(Cohort, :count)
        .and not_change(Schedule, :count)
        .and not_change(Application, :count)
        .and not_change(User, :count)
    end
  end

  context "when running for real" do
    it "Adds 2026b courses" do
      expect { run_task }
        .to change(Cohort, :count).from(3).to(4)
        .and change(Schedule, :count).from(1).to(12)
        .and change(Application, :count).from(0).to(78)
        .and change(User, :count).from(0).to(78)
    end
  end
end
