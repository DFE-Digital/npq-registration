require "rspec/mocks"

RSpec::Matchers.define :send_mail do |mailer_action, deliver_now: false|
  match do |mailer_class|
    message_delivery = instance_double(ActionMailer::MessageDelivery)
    allow(mailer_class).to receive(mailer_action).and_return(message_delivery)
    expect(mailer_class).to receive(mailer_action).with(@mailer_params)
    delivery_method = deliver_now ? :deliver_now : :deliver_later
    expect(message_delivery).to receive(delivery_method)
  end

  match_when_negated do |mailer_class|
    expect(mailer_class).not_to receive(mailer_action)
  end

  def with_params(params)
    @mailer_params = params
    self
  end
end
