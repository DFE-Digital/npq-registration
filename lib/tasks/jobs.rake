namespace :db do
  desc "Schedule all cron jobs"
  task schedule_jobs: :environment do
    glob = Rails.root.join("app/jobs/**/*_job.rb")
    Dir.glob(glob).each { |file| require file }
    CronJob.subclasses.each(&:schedule)
  end
end
