def dqt_response_body(trn: "1234567", date_of_birth: "1960-12-13")
  {
    data: {
      attributes: {
        teacher_reference_number: trn,
        full_name: "John Doe",
        date_of_birth: date_of_birth,
        national_insurance_number: "AB123456C",
        qts_date: "1990-12-13",
        active_alert: false,
      },
    },
  }.to_json
end
