namespace :large_seed do
  desc "Load large-scale application seeds in background"
  task background: :versioned_environment do
    SeedingJob.perform_later(times: 2)
  end

  desc "Load large-scale application seeds in foreground"
  task now: :versioned_environment do
    puts "Application count: #{Application.count}"
    puts "Loading seeds"
    SeedingJob.perform_now
    puts "Application count: #{Application.count}"
  end

  desc "Check the status of large-scale application seeds background jobs"
  task check: :versioned_environment do
    jobs = Delayed::Job.all.select { |job| job.payload_object.job_data["job_class"] == SeedingJob.to_s }
    puts "-------------------------"
    puts "Application count: #{Application.count}"
    puts "Declaration count: #{Declaration.count}"
    puts "User count: #{User.count}"

    if jobs.empty?
      puts "No SeedingJob jobs found."
      exit 0
    end

    jobs.each do |job|
      puts "-------------------------"
      puts "Job ID: #{job.id}"
      puts "Created at: #{job.created_at}"
      puts "Locked at: #{job.locked_at}" if job.locked_at
      scheduled_or_running = job.run_at.future? ? " (scheduled)" : " (running)"
      puts "Run at: #{job.run_at}#{scheduled_or_running}"
      iterations_left = job.payload_object.job_data["arguments"].first["times"]
      puts "Iterations left: #{iterations_left}"

      next unless job.failed_at

      puts "Failed at: #{job.failed_at}"
      puts "Last error: #{job.last_error}"
      puts "Attempts: #{job.attempts}"
    end
  end
end
