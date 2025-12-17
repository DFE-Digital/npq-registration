require "rails_helper"

RSpec.describe OneOff::MoveApplicationsToAutumn2025 do
  subject :perform do
    Tempfile.open do |changelog|
      described_class.new(lead_provider:, changelog:, limit:)
                     .move!(dry_run:)
    end
  end

  before { autumn_statement }

  let(:lead_provider) { create(:lead_provider) }
  let(:dry_run) { false }
  let(:limit) { 2000 }
  let(:spring) { create(:cohort, start_year: 2025, suffix: "a") }
  let(:autumn) { create(:cohort, start_year: 2025, suffix: "b") }

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
        expect { perform }
          .to change { applications[0].reload.cohort }.from(spring).to(autumn)
          .and change { applications[1].reload.cohort }.from(spring).to(autumn)
          .and change { applications[2].reload.cohort }.from(spring).to(autumn)
      end

      it "does not change application timestamps" do
        expect { perform }
          .to change { applications[0].reload.cohort }.from(spring).to(autumn)
          .and(not_change { applications[0].reload.updated_at })
          .and(not_change { applications[0].user.reload.updated_at })
      end

      it "creates version records for the changes", :versioning do
        perform

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
        expect { perform }
          .to change { applications[0].reload.cohort }.from(spring).to(autumn)
          .and change { applications[0].reload.schedule }.from(spring_schedule).to(autumn_schedule)
          .and change { applications[1].reload.cohort }.from(spring).to(autumn)
      end

      context "with missing schedules in autumn cohort" do
        let(:spring_schedule) { create(:schedule, :npq_leadership_spring, cohort: spring) }

        it "does not move applications between cohorts" do
          expect { perform }
            .to not_change { applications[0].reload.cohort }
            .and(not_change { applications[0].reload.schedule })
            .and(change { applications[1].reload.cohort })
            .and(change { applications[2].reload.cohort })
        end
      end
    end

    context "with some from spring cohort which should not be moved" do
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
        expect { perform }
          .to not_change { spring_applications[0].reload.cohort }
          .and not_change { spring_applications[1].reload.cohort }
          .and change { autumn_applications[0].reload.cohort }.from(spring).to(autumn)
          .and change { autumn_applications[1].reload.cohort }.from(spring).to(autumn)
      end
    end

    context "with more applications than the limit" do
      let(:limit) { 2 }

      it "moves applications within the limit to autumn cohort" do
        expect { perform }
          .to change { applications[0].reload.cohort }.from(spring).to(autumn)
          .and change { applications[1].reload.cohort }.from(spring).to(autumn)
          .and(not_change { applications[2].reload.cohort })
      end
    end
  end

  context "with applications for another lead provider" do
    subject :perform do
      Tempfile.open do |changelog|
        described_class.new(lead_provider: another_provider, changelog:, limit:)
                       .move!(dry_run:)
      end
    end

    before { applications && autumn && another_provider_statement }

    let(:another_provider) { create(:lead_provider) }

    let :another_provider_statement do
      create :statement, :open, :next_output_fee, cohort: autumn,
                                                  lead_provider: another_provider
    end

    it "does not change those applications" do
      expect { perform }
        .to not_change { applications[0].reload.cohort }
        .and(not_change { applications[1].reload.cohort })
        .and(not_change { applications[2].reload.cohort })
    end
  end

  context "without a suitable output statement to move to" do
    before { autumn && applications }

    let(:autumn_statement) {}

    it "raises an exception" do
      expect { perform }
        .to raise_exception(RuntimeError, /No output fee statement/)
        .and(not_change { applications[0].reload.cohort })
    end
  end

  context "when an application has declarations" do
    before do
      autumn && applications

      travel_to 10.days.ago do
        declaration && spring_statement && autumn_statement
      end
    end

    let(:declaration) { create :declaration, application: applications[1] }

    let :spring_statement do
      create :statement, :open, :next_output_fee, cohort: spring,
                                                  lead_provider:,
                                                  declaration:
    end

    it "moves declarations between cohorts and attaches to new statement" do
      expect { perform }
        .to change { applications[1].declarations.first.cohort }.from(spring).to(autumn)
        .and change { applications[1].declarations.first.updated_at }
                    .from(be_within(5.seconds).of(10.days.ago))
                    .to(be_within(5.seconds).of(Time.zone.now))
    end

    it "does not update the applications timestamp" do
      expect { perform }
        .to not_change { applications[1].reload.updated_at }
        .and(not_change { applications[1].user.reload.updated_at })
    end

    it "creates a version record for the declarations cohort change", :versioning do
      perform

      expect(applications[1].declarations.first.versions.last)
          .to have_attributes "object_changes" => { "cohort_id" => [spring.id, autumn.id] },
                              "created_at" => be_within(5.seconds).of(Time.zone.now)
    end

    it "attaches declarations to appropriate statement in autumn cohort" do
      expect { perform }
        .to change { applications[1].declarations.first.statements }
                    .from([spring_statement])
                    .to([autumn_statement])
    end

    it "creates a version record for the statement change", :versioning do
      perform

      expect(applications[1].declarations.first.statement_items.first.versions.last)
          .to have_attributes("created_at" => be_within(5.seconds).of(Time.zone.now),
                              "object_changes" => {
                                "statement_id" => [spring_statement.id, autumn_statement.id],
                              })
    end

    it "rejects changes if any declarations are on payable statements" do
      Statements::MarkAsPayable.new(statement: spring_statement).mark

      expect { perform }
        .to raise_exception(RuntimeError, /payable statements/i)
        .and(not_change { applications[1].cohort })
        .and(not_change { applications[1].declarations.first.statements.to_a })
    end

    it "rejects changes if any declarations are on paid statements" do
      Statements::MarkAsPayable.new(statement: spring_statement).mark
      Statements::MarkAsPaid.new(spring_statement).mark

      expect { perform }
        .to raise_exception(RuntimeError, /payable statements/i)
        .and(not_change { applications[1].cohort })
        .and(not_change { applications[1].declarations.first.statements.to_a })
    end

    context "with declarations against a different cohort" do
      let :declaration do
        create :declaration, application: applications[1], cohort: other_cohort
      end

      let(:other_cohort) { create :cohort, start_year: 2024 }

      it "changes the cohort for the application but not the declaration" do
        expect { perform }
          .to change { applications[1].reload.cohort }.from(spring).to(autumn)
          .and(not_change { applications[1].declarations.first.cohort })
      end
    end

    context "when the applicant is unfunded" do
      let :spring_statement do
        create :statement, :open, :next_output_fee, cohort: spring, lead_provider:
      end

      it "moves declarations between cohorts without changing timestamps" do
        expect { perform }
          .to change { applications[1].declarations.first.cohort }.from(spring).to(autumn)
          .and(not_change { applications[1].declarations.first.updated_at })
      end

      it "creates a version record for the declarations cohort change", :versioning do
        perform

        expect(applications[1].declarations.first.versions.last)
            .to have_attributes "object_changes" => { "cohort_id" => [spring.id, autumn.id] },
                                "created_at" => be_within(5.seconds).of(Time.zone.now)
      end
    end
  end

  context "when performing a dry run" do
    before { applications && autumn }

    let(:dry_run) { nil }

    it "does not change those applications" do
      expect { perform }
        .to not_change { applications[0].reload.cohort }
        .and(not_change { applications[1].reload.cohort })
        .and(not_change { applications[2].reload.cohort })
    end
  end
end
