require File.expand_path(File.join(File.dirname(__FILE__), "..", "config", "environment"))

every 1.day, at: "00:00" do
  runner "ApplicationSynchronizationJob.perform_now", environment: Rails.env
end
