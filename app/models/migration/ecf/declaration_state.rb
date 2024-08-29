module Migration::Ecf
  class DeclarationState < BaseRecord
    belongs_to :participant_declaration

    enum state: {
      submitted: "submitted",
      eligible: "eligible",
      payable: "payable",
      paid: "paid",
      voided: "voided",
      ineligible: "ineligible",
      awaiting_clawback: "awaiting_clawback",
      clawed_back: "clawed_back",
    }
  end
end
