APPLICATIONS_CSV_RESPONSE = {
  description: "A list of NPQ applications in the Comma Separated Value (CSV) format",
  type: :string,
  required: %i[data],
  properties: {
    data: {
      type: :array,
      items: { "$ref": "#/components/schemas/ApplicationCsv" },
    },
  },
  example: "id,participant_id,full_name,email,email_validated,teacher_reference_number,teacher_reference_number_validated,school_urn,school_ukprn,private_childcare_provider_urn,headteacher_status,eligible_for_funding,funding_choice,course_identifier,status,works_in_school,employer_name,employment_role,created_at,updated_at,cohort,ineligible_for_funding_reason,targeted_delivery_funding_eligibility,teacher_catchment,teacher_catchment_country,teacher_catchment_iso_country_code,itt_provider,lead_mentor\n"\
           "db3a7848-7308-4879-942a-c4a70ced400a,7a8fef46-3c43-42c0-b3d5-1ba5904ba562,Isabelle MacDonald,isabelle.macdonald2@some-school.example.com,true,1234567,false,100015,10005549,,no,false,trust,npq-early-headship-coaching-offer,accepted,true,,,2024-04-23T15:52:03Z,2024-04-23T15:52:03Z,2021,establishment-ineligible,false,true,United Kingdom of Great Britain and Northern Ireland,GBR,Test ITT Provider,false",
}.freeze
