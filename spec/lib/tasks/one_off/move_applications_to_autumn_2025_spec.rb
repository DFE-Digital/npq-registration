require "rails_helper"

RSpec.describe "one_off:move_applications_to_autumn_2025" do
  subject :run_task do
    Rake::Task["one_off:move_applications_to_autumn_2025"].invoke(lead_provider.id, dry_run)
  end

  after { Rake::Task["one_off:move_applications_to_autumn_2025"].reenable }

  let(:lead_provider) { create(:lead_provider) }
  let(:dry_run) { "false" }
  let(:spring) { create(:cohort, start_year: 2025, suffix: 1) }
  let(:autumn) { create(:cohort, start_year: 2025, suffix: 2) }

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

      it "does not change application timestamps" do
        expect { run_task }
          .to change { applications[0].reload.cohort }.from(spring).to(autumn)
          .and(not_change { applications[0].reload.updated_at })
      end

      it "creates version records for the changes", :versioning do
        run_task

        expect(applications[1].versions.last)
          .to have_attributes "object_changes" => { "cohort_id" => [spring.id, autumn.id] },
                              "created_at" => be_within(5.seconds).of(Time.zone.now)
      end
    end

    context "with accepted applications" do
      before do
        spring_schedule && autumn_schedule

        Applications::Accept
          .new(application: applications[0],
               funded_place: false,
               schedule_identifier: spring_schedule.identifier)
          .accept || raise("failed to accept")
      end

      it "moves applications to autumn cohort and new schedule" do
        expect { run_task }
          .to change { applications[0].reload.cohort }.from(spring).to(autumn)
          .and change { applications[0].reload.schedule }.from(spring_schedule).to(autumn_schedule)
          .and change { applications[1].reload.cohort }.from(spring).to(autumn)
      end

      context "with missing schedules in autumn cohort" do
        let(:spring_schedule) { create(:schedule, :npq_leadership_spring, cohort: spring) }

        it "does not move applications between cohorts" do
          expect { run_task }
            .to raise_exception(RuntimeError, /Missing schedules/)
            .and(not_change { applications[0].reload.cohort })
            .and(not_change { applications[0].reload.schedule })
            .and(not_change { applications[1].reload.cohort })
        end
      end
    end

    context "and some from spring cohort which should not be moved" do
      let(:applications) { spring_applications + autumn_applications }

      let :spring_applications do
        travel_to Time.zone.parse("2025-03-01") do
          create_pair(:application, cohort: spring, lead_provider:)
        end
      end

      let :autumn_applications do
        travel_to Time.zone.parse("2025-10-01") do
          create_pair(:application, cohort: spring, lead_provider:)
        end
      end

      it "moves only the autumn applications to autumn cohort" do
        expect { run_task }
          .to not_change { spring_applications[0].reload.cohort }
          .and not_change { spring_applications[1].reload.cohort }
          .and change { autumn_applications[0].reload.cohort }.from(spring).to(autumn)
          .and change { autumn_applications[1].reload.cohort }.from(spring).to(autumn)
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

  context "with applications for another lead provider" do
    subject :run_task do
      Rake::Task["one_off:move_applications_to_autumn_2025"]
        .invoke(another_provider.id, false)
    end

    before { applications && autumn }

    let(:another_provider) { create(:lead_provider) }

    it "does not change those applications" do
      expect { run_task }
        .to not_change { applications[0].reload.cohort }
        .and(not_change { applications[1].reload.cohort })
        .and(not_change { applications[2].reload.cohort })
    end
  end

  context "when an application has declarations" do
    before { autumn && declaration }

    let(:declaration) { create :declaration, application: applications[1] }

    it "does not move applications between cohorts" do
      expect { run_task }
        .to raise_exception(RuntimeError, /have declarations/)
        .and(not_change { applications[0].reload.cohort })
        .and(not_change { applications[1].reload.cohort })
        .and(not_change { applications[2].reload.cohort })
    end
  end

  context "when performing a dry run" do
    before { applications && autumn }

    let(:dry_run) { nil }

    it "does not change those applications" do
      expect { run_task }
        .to not_change { applications[0].reload.cohort }
        .and(not_change { applications[1].reload.cohort })
        .and(not_change { applications[2].reload.cohort })
    end
  end
end
