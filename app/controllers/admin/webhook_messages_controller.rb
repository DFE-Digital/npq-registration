class Admin::WebhookMessagesController < AdminController
  def index
    @pagy, @webhook_messages = pagy(scope)
    @message_types = GetAnIdentity::WebhookMessage.distinct.pluck(:message_type).compact.sort
  end

  def show
    @webhook_message = GetAnIdentity::WebhookMessage.find(params[:id])
  end

private

  def filter_params
    params.permit(%i[message_type status]).compact_blank
  end

  def scope
    GetAnIdentity::WebhookMessage.where(filter_params).order(created_at: :desc, id: :desc)
  end
end
