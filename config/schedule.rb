every :day, at: "12pm" do
  runner "ReceiveLeadProviderApprovalStatusFromEcf.perform_now"
end
