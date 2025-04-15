# FYI currently we are specifying the queue list in terraform.
# If you add a new queue, you'll need to update the file:
# `terraform/application/application.tf` - line 72

Delayed::Worker.queue_attributes = {
  high_priority: { priority: -10 },
  default: { priority: 0 },
  participant_outcomes: { priority: 5 },
  low_priority: { priority: 10 },
  dfe_analytics: { priority: 0 },
}

# Non of our jobs should take longer than this and if they are they should be
# broken up into multiple jobs
Delayed::Worker.max_run_time = 30.minutes

# The default of 25 is too high, instead we should retry less times and with
# lower frequency
Delayed::Worker.max_attempts = 8

Delayed::Worker.sleep_delay = 30
# Delayed::Worker.raise_signal_exceptions = true

# Override backoff rate for retries
ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.class_eval do
  def reschedule_at(db_time_now, attempts, ...)
    db_time_now + (attempts**6) + 5
  end
end

Delayed::Worker.class_eval do
  def start
    trap('TERM') do
      Thread.new { say "Exiting from TERM... at #{Time.zone.now}" }
      stop
      raise SignalException, 'TERM' if self.class.raise_signal_exceptions
    end

    trap('INT') do
      Thread.new { say "Exiting from INT... at #{Time.zone.now}" }
      stop
      raise SignalException, 'INT' if self.class.raise_signal_exceptions && self.class.raise_signal_exceptions != :term
    end

    say 'Starting job worker'

    self.class.lifecycle.run_callbacks(:execute, self) do
      loop do
        self.class.lifecycle.run_callbacks(:loop, self) do
          @realtime = Benchmark.realtime do
            @result = work_off
          end
        end

        count = @result[0] + @result[1]

        if count.zero?
          if self.class.exit_on_complete
            say 'No more jobs available. Exiting'
            break
          elsif !stop?
            say "Sleeping for #{self.class.sleep_delay} seconds at #{Time.zone.now}"
            1.upto(self.class.sleep_delay) do
              sleep(1) if !stop?
            end
            reload!
          end
        else
          say format("#{count} jobs processed at %.4f j/s, %d failed", count / @realtime, @result.last)
        end

        break if stop?
      end

      say "FINALLY STOPPING at #{Time.zone.now}"
    end
  end
end if Rails.env.review?
