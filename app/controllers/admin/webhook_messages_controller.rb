class Admin::WebhookMessagesController < AdminController
  def index
    @form = ::Admin::WebhookMessagesForm.new(filter_params)
    @pagy, @webhook_messages = pagy(@form.search_scope.order(sent_at: :desc, id: :desc))
    @message_types = WebhookMessage.distinct.pluck(:message_type).compact.sort
  end

  def show
    @webhook_message = WebhookMessage.find(params[:id])
  end

private

  def filter_params
    params.fetch(:webhook_messages, {}).permit(%i[q message_type status sent_at_start sent_at_end]).compact_blank
  end
end
