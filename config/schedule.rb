every :day, at: "12pm" do
  runner "ApplicationSynchronizationJob.perform_now"
end
