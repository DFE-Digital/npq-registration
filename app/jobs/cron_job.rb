#
# Base class for all the Cron jobs of the application. Cron jobs are recurring tasks
# that are scheduled to run at specific intervals, and this class provides a framework
# for creating and managing such jobs in your application.
#
# This class relies on the 'delayed_cron_job' gem for handling the scheduling of cron jobs.
# It extends DelayedJob, adding a `cron` column to store the cron expression for each job.
#
# For more information on using this custom cron job superclass and configuring cron jobs
# in your application, please refer to the documentation at:
#
# https://github.com/codez/delayed_cron_job#custom-cronjob-superclass
class CronJob < ApplicationJob
  class_attribute :cron_expression

  class << self
    # Schedules the cron job, ensuring that it is not rescheduled while already in progress.
    #
    # This method checks whether the job is already scheduled in the DelayedJob queue. If it is,
    # it further examines if the job is currently running (locked). If the job is running, it raises
    # an exception indicating that it cannot be rescheduled while active. To reschedule the job,
    # it follows the requirement set by the gem's API by first removing the existing job from the queue
    # and then scheduling it again with the specified cron expression.
    #
    # Raises:
    #   RuntimeError: If the job is running and cannot be rescheduled.
    def schedule
      if scheduled?
        if already_running?
          Sentry.capture_message "Job #{name} is already running and cannot be scheduled."
        else
          delayed_job.destroy!
        end
      end

      set(cron: cron_expression).perform_later
    end

    def delayed_job
      Delayed::Job
        .where("handler LIKE ?", "%job_class: #{name}%")
        .first
    end

    def scheduled?
      delayed_job.present?
    end

    def already_running?
      delayed_job.locked_at.present?
    end
  end

  def perform; end
end
