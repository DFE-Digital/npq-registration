# frozen_string_literal: true

class Admin::WebhookMessagesForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :q
  attribute :message_type
  attribute :status
  attribute :message_source
  attribute :"sent_at_start(3i)"
  attribute :"sent_at_start(2i)"
  attribute :"sent_at_start(1i)"
  attribute :"sent_at_end(3i)"
  attribute :"sent_at_end(2i)"
  attribute :"sent_at_end(1i)"

  def search_scope
    scope = WebhookMessage
    scope = scope.where(message_type:) if message_type.present?
    scope = scope.where(status:) if status.present?
    scope = scope.where("message::text like ?", "%#{q}%") if q.present?
    scope = scope.where("sent_at >= ?", sent_at_start) if sent_at_start.present?
    scope = scope.where("sent_at <= ?", sent_at_end) if sent_at_end.present?
    scope
  end

  def sent_at_start
    date_attributes = attributes.values_at("sent_at_start(1i)", "sent_at_start(2i)", "sent_at_start(3i)")
    return unless date_attributes.compact.size == 3

    Date.new(*date_attributes.map(&:to_i)).beginning_of_day
  end

  def sent_at_end
    date_attributes = attributes.values_at("sent_at_end(1i)", "sent_at_end(2i)", "sent_at_end(3i)")
    return unless date_attributes.compact.size == 3

    Date.new(*date_attributes.map(&:to_i)).end_of_day
  end
end
