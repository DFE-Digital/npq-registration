class DelayedCronJobRakeTask
  include Rake::DSL

  def initialize
    namespace :delayed_cron_job do
      desc "Schedule or delete delayed cron jobs"
      task schedule: :versioned_environment do
        # Need to load all jobs definitions in order to find subclasses
        # based on: https://github.com/codez/delayed_cron_job#automatic-scheduling-after-dbmigrate
        glob = Rails.root.join("app/jobs/**/*_job.rb")
        Dir.glob(glob).each { |file| require file }

        Delayed::Job.transaction do
          Delayed::Job.with_advisory_lock!("lock-delayed-cron-job", blocking: true, transaction: true) do
            handle_new_cron_jobs
            handle_existing_cron_delayed_jobs
          end
        end
      end
    end
  end

private

  def handle_new_cron_jobs
    CronJob.subclasses.each do |cron_job_class|
      if cron_job_class.scheduled?
        logger.info "cron job already scheduled: #{cron_job_class}"
      else
        next if cron_job_class.production_only && !Rails.env.production?

        logger.info "scheduling new cron job: #{cron_job_class}"
        cron_job_class.schedule
      end
    end
  end

  def handle_existing_cron_delayed_jobs
    cron_delayed_jobs.each do |delayed_job|
      cron_job_class = cron_job_class(delayed_job)
      cron_job = cron_job_class_constant(cron_job_class)

      if cron_job
        if cron_job.production_only && !Rails.env.production?
          logger.info "delayed job has changed to production only - deleting delayed job: #{cron_job_class}"
          delayed_job.destroy!
          next
        end

        next if cron_job.cron_expression == delayed_job.cron

        logger.info "delayed job found with out-of-date cron expression - rescheduling cron job: #{cron_job_class}"
        delayed_job.destroy!
        cron_job.schedule
      else
        logger.info "delayed job found for deleted cron job - deleting delayed job: #{cron_job_class}"
        delayed_job.destroy!
      end
    end
  end

  def cron_job_class(delayed_job)
    delayed_job.payload_object.job_data["job_class"]
  end

  def cron_delayed_jobs
    Delayed::Job.where.not(cron: nil)
  end

  def cron_job_class_constant(cron_job_class)
    cron_job_class.constantize
  rescue NameError
    nil
  end

  def logger
    @logger ||= Rails.env.test? ? Rails.logger : Logger.new($stdout)
  end
end

DelayedCronJobRakeTask.new

Rake::Task["db:migrate"].enhance do
  Rake::Task["delayed_cron_job:schedule"].invoke
end
