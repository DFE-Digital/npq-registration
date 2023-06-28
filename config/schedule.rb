require File.expand_path(File.join(File.dirname(__FILE__), "..", "config", "environment"))

every 3.hours do
  runner "ApplicationSynchronizationJob.perform_now", environment: Rails.env
end
