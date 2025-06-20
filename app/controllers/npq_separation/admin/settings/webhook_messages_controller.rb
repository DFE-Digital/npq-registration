class NpqSeparation::Admin::Settings::WebhookMessagesController < NpqSeparation::AdminController
  def index
    @pagy, @webhook_messages = pagy(scope)
  end

  def show
    @webhook_message = GetAnIdentity::WebhookMessage.find(params[:id])
  end

private

  def scope
    GetAnIdentity::WebhookMessage.all.order(created_at: :desc, id: :desc)
  end
end
