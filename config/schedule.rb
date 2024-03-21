require File.expand_path(File.join(File.dirname(__FILE__), "..", "config", "environment"))

every 1.day, at: "00:00" do
  runner "ApplicationSynchronizationJob.perform_later", environment: Rails.env
end

every 2.hours do
  runner "Crons::UpdateTsfPrimaryAttributesJob.perform_later", environment: Rails.env
end
