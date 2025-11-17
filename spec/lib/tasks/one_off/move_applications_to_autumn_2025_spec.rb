require "rails_helper"

RSpec.describe "one_off:move_applications_to_autumn_2025" do
  subject :run_task do
    Rake::Task["one_off:move_applications_to_autumn_2025"].invoke(lead_provider.id, "false")
  end

  before { autumn_statement }
  after { Rake::Task["one_off:move_applications_to_autumn_2025"].reenable }

  let(:lead_provider) { create(:lead_provider) }
  let(:spring) { create(:cohort, start_year: 2025, suffix: 1) }
  let(:autumn) { create(:cohort, start_year: 2025, suffix: 2) }

  let :autumn_statement do
    create :statement, :open, :next_output_fee, cohort: autumn,
                                                lead_provider:
  end

  let :applications do
    travel_to Time.zone.parse("2025-10-01") do
      create_list(:application, 3, cohort: spring, lead_provider:)
    end
  end

  context "with applications in spring cohort to be moved" do
    let(:spring_schedule) { create(:schedule, :npq_leadership_autumn, cohort: spring) }
    let(:autumn_schedule) { create(:schedule, :npq_leadership_autumn, cohort: autumn) }

    context "and autumn cohort correctly setup" do
      before { autumn && applications }

      it "moves applications to autumn cohort" do
        expect { run_task }
          .to change { applications[0].reload.cohort }.from(spring).to(autumn)
          .and change { applications[1].reload.cohort }.from(spring).to(autumn)
          .and change { applications[2].reload.cohort }.from(spring).to(autumn)
      end
    end
  end

  context "with unknown lead provider" do
    subject :run_task do
      Rake::Task["one_off:move_applications_to_autumn_2025"].invoke(999, false)
    end

    before { applications && autumn }

    it "raises an exception" do
      expect { run_task }
        .to raise_exception(ActiveRecord::RecordNotFound)
        .and(not_change { applications[0].reload.cohort })
        .and(not_change { applications[1].reload.cohort })
        .and(not_change { applications[2].reload.cohort })
    end
  end

  context "when performing a dry run" do
    subject :run_task do
      Rake::Task["one_off:move_applications_to_autumn_2025"].invoke(lead_provider.id, nil)
    end

    before { applications && autumn }

    it "does not change those applications" do
      expect { run_task }
        .to not_change { applications[0].reload.cohort }
        .and(not_change { applications[1].reload.cohort })
        .and(not_change { applications[2].reload.cohort })
    end
  end
end
