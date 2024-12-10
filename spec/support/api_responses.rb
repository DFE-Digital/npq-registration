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

def participant_validator_response(state_name: "Active", trn: "1234567", name: "Jane Smith", ni_number: "AB123456C", dob: "1960-12-13", active_alert: false)
  {
    state_name:,
    trn:,
    name:,
    ni_number:,
    dob:,
    active_alert:,
  }.to_json
end
