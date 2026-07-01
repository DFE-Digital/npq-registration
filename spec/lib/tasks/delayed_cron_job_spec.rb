require "rails_helper"

RSpec.describe "Delayed::Cron::Job tasks" do
  describe "delayed_cron_job:schedule" do
    include ActiveJob::TestHelper

    subject(:run_task) { Rake::Task["delayed_cron_job:schedule"].invoke }

    after { Rake::Task["delayed_cron_job:schedule"].reenable }

    let(:current_cron_jobs) { [] }
    let(:all_delayed_jobs) { Delayed::Job }
    let(:cron_delayed_jobs) { Delayed::Job.where.not(cron: nil) }

    let(:scheduled_cron_job_class) do
      Class.new(CronJob) do
        self.cron_expression = "31 1 * * *"

        def self.scheduled?
          true
        end

        def self.delayed_job
          Delayed::Job.new
        end
      end
    end

    let(:not_scheduled_cron_job_class) do
      Class.new(CronJob) do
        def self.scheduled?
          false
        end
      end
    end

    let(:production_only_cron_job_class) do
      Class.new(CronJob) do
        self.production_only = true

        def self.scheduled?
          false
        end
      end
    end

    before do
      stub_const("ScheduledCronJob", scheduled_cron_job_class)
      stub_const("NotScheduledCronJob", not_scheduled_cron_job_class)
      stub_const("NonCronJob", Class.new(ApplicationJob))
      stub_const("ProductionOnlyNotScheduledCronJob", production_only_cron_job_class)
      allow(CronJob).to receive(:subclasses).and_return(current_cron_jobs)
    end

    shared_examples_for "using an advisory lock" do
      it "uses an advisory lock" do
        expect(Delayed::Job).to receive(:with_advisory_lock!)
          .with("lock-delayed-cron-job", blocking: true, transaction: true)
          .and_yield
        subject
      end
    end

    context "when there is a new delayed cron job" do
      let(:current_cron_jobs) { [ScheduledCronJob, NotScheduledCronJob] }

      before { ScheduledCronJob.schedule }

      it_behaves_like "using an advisory lock"

      it "schedules the new cron job" do
        expect { run_task }.to have_enqueued_job(NotScheduledCronJob)
      end

      it "does not schedule the existing cron job" do
        expect { run_task }.not_to have_enqueued_job(ScheduledCronJob)
      end

      context "when the cron job is production only" do
        let(:current_cron_jobs) { [ScheduledCronJob, ProductionOnlyNotScheduledCronJob] }

        context "and the environment is production" do
          before { allow(Rails).to receive(:env) { "production".inquiry } }

          it "schedules the new cron job" do
            expect { run_task }.to have_enqueued_job(ProductionOnlyNotScheduledCronJob)
          end
        end

        context "and the environment is not production" do
          it "does not schedule the new cron job" do
            expect { run_task }.not_to have_enqueued_job(ProductionOnlyNotScheduledCronJob)
          end
        end
      end
    end

    context "when there is a deleted delayed cron job" do
      let(:current_cron_jobs) { [ScheduledCronJob] }

      before do
        scheduled_job = Delayed::Job.enqueue ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new("job_class" => ScheduledCronJob.to_s)
        scheduled_job.update!(cron: "31 1 * * *")
        deleted_job = Delayed::Job.enqueue ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new("job_class" => "DeletedCronJob")
        deleted_job.update!(cron: "31 1 * * *")
        Delayed::Job.enqueue NonCronJob.new
      end

      it_behaves_like "using an advisory lock"

      it "deletes the delayed job for the deleted cron job" do
        expect { run_task }.to change(all_delayed_jobs, :count).from(3).to(2)
          .and(change(cron_delayed_jobs, :count).from(2).to(1))
        expect(cron_delayed_jobs.first.payload_object.job_data["job_class"]).to eq ScheduledCronJob.to_s
      end
    end

    context "when a cron job is changed from 'all environments allowed' to production-only" do
      let(:current_cron_jobs) { [ScheduledCronJob] }

      before do
        scheduled_job = Delayed::Job.enqueue ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new("job_class" => ScheduledCronJob.to_s)
        scheduled_job.update!(cron: "31 1 * * *")
        stub_const("ScheduledCronJob", production_only_cron_job_class)
      end

      it_behaves_like "using an advisory lock"

      it "deletes the delayed job for the deleted cron job" do
        expect { run_task }.to change(cron_delayed_jobs, :count).from(1).to(0)
      end

      it "does not re-schedule to cron job" do
        expect { run_task }.not_to have_enqueued_job
      end
    end

    context "when the cron schedule changes on an existing cron job" do
      let(:current_cron_jobs) { [ScheduledCronJob] }

      before do
        scheduled_job = Delayed::Job.enqueue ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new("job_class" => ScheduledCronJob.to_s)
        scheduled_job.update!(cron: "31 2 * * *")
      end

      it_behaves_like "using an advisory lock"

      it "reschedules the job" do
        expect { run_task }.to change(cron_delayed_jobs, :count).from(1).to(0).and have_enqueued_job(ScheduledCronJob)
      end
    end

    context "when db:migrate is run" do
      let(:rake_task_stub) { instance_double(Rake::Task, reenable: true) }

      before do
        allow(Rake::Task).to receive(:[]).and_call_original
        allow(Rake::Task).to receive(:[]).with("delayed_cron_job:schedule").and_return(rake_task_stub)
      end

      it "invokes the delayed_cron_job:schedule task" do
        expect(rake_task_stub).to receive(:invoke)
        Rake::Task["db:migrate"].invoke
      end
    end
  end
end
