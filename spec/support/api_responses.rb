def dqt_response_body(trn: "1234567", date_of_birth: "1960-12-13", active_alert: false)
  {
    "trn": trn,
    "ni_number": "AB123456C",
    "name": "Jane Doe",
    "dob": date_of_birth,
    "active_alert": active_alert,
    "state_name": "Active",
  }.to_json
end

def ecf_funding_lookup_response(previously_funded:, previously_received_targeted_funding_support: false)
  {
    previously_funded:,
    previously_received_targeted_funding_support:,
  }.to_json
end
