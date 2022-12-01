def dqt_response_body(trn: "1234567", date_of_birth: "1960-12-13", active_alert: false)
  {
    data: {
      attributes: {
        teacher_reference_number: trn,
        full_name: "John Doe",
        date_of_birth:,
        national_insurance_number: "AB123456C",
        qts_date: "1990-12-13",
        active_alert:,
      },
    },
  }.to_json
end

def participant_validator_response(trn: "1234567", active_alert: false)
  {
    data: {
      attributes: {
        trn:,
        qts: true,
        active_alert:,
      },
    },
  }.to_json
end

def ecf_funding_lookup_response(previously_funded:, previously_received_targeted_funding_support: false)
  {
    previously_funded:,
    previously_received_targeted_funding_support:,
  }.to_json
end
