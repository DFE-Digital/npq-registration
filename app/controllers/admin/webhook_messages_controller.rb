class Admin::WebhookMessagesController < AdminController
  include Pagy::Backend

  def index
    @pagy, @webhook_messages = pagy(scope)
  end

  def show
    @webhook_message = GetAnIdentity::WebhookMessage.find(params[:id])
  end

  private

  def scope
    GetAnIdentity::WebhookMessage.all.order(created_at: :desc)
  end
end
