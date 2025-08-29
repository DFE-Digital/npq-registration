class NpqSeparation::Admin::WebhookMessages::ProcessingJobsController < NpqSeparation::AdminController
  def create
    @webhook_message = GetAnIdentity::WebhookMessage.find(params[:webhook_message_id])
    @webhook_message.update!(status: :pending)
    @webhook_message.enqueue_processing_job

    redirect_to npq_separation_admin_webhook_message_path(@webhook_message)
  end
end
