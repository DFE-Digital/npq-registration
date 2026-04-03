class StreamVersionsToBigQueryJob < ApplicationJob
  delegate :dfe_analytics_enabled?, to: Feature

  self.log_arguments = false

  queue_as :low_priority

  def perform(user_name, data)
    return unless dfe_analytics_enabled?

    event = DfE::Analytics::Event.new
      .with_type(:version)
      .with_user(user_name)
      .with_namespace("npq")
      .with_data(data:)

    DfE::Analytics::SendEvents.do(Array.wrap(event))
  end
end
