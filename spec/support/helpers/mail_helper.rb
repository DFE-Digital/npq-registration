module Helpers
  module MailHelper
    def expect_mail_to_have_been_sent(to:, template_id:)
      expect(ActionMailer::Base.deliveries.count { |mail| mail.to == [to] && mail.template_id == template_id }).to eq(1)
    end
  end
end
