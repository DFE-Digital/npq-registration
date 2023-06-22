class ReceiveLeadProviderApprovalStatusFromEcf < ApplicationJob
  queue_as :default
  def perform
    Services::Ecf::EcfLeadProviderApprovalStatusReciever.new.call
  end
end
