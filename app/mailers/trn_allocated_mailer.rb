class TrnAllocatedMailer < ApplicationMailer
  TEMPLATE_ID = "208495e9-7cfc-4fc6-abb4-30df2c5329c4".freeze

  def trn_allocated_mail(to:, full_name:, trn:)
    template_mail(TEMPLATE_ID,
                  to:,
                  personalisation: {
                    full_name:,
                    trn:,
                  })
  end
end
