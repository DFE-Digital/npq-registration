APPLICATIONS_CSV_RESPONSE = {
  v1: {
    description: "A list of NPQ applications in the Comma Separated Value (CSV) format",
    properties: {
      example: {
        type: :array,
        items: { "$ref": "#/components/schemas/ApplicationCsv" },
      },
    },
    example: "id,participant_id,full_name,email,email_validated,teacher_reference_number,\n" \
            "teacher_reference_number_validated,school_urn,school_ukprn,private_childcare_provider_urn,\n" \
            "headteacher_status,eligible_for_funding,funding_choice,course_identifier,\n" \
            "status,works_in_school,employer_name,employment_role,created_at,updated_at,\n" \
            "cohort,ineligible_for_funding_reason,targeted_delivery_funding_eligibility,\n" \
            "teacher_catchment,teacher_catchment_country,teacher_catchment_iso_country_code,itt_provider,lead_mentor\n"\
            "db3a7848-7308-4879-942a-c4a70ced400a,7a8fef46-3c43-42c0-b3d5-1ba5904ba562,\n" \
            "Isabelle MacDonald,isabelle.macdonald2@some-school.example.com,true,1234567,\n" \
            "false,100015,10005549,,no,false,trust,npq-early-headship-coaching-offer,\n" \
            "accepted,true,,,2024-04-23T15:52:03Z,2024-04-23T15:52:03Z,2021,\n" \
            "establishment-ineligible,false,true,United Kingdom of Great Britain and Northern Ireland\n" \
            ",GBR,Test ITT Provider,false\n",
  },
}.tap { |h|
  h[:v2] = h[:v1].deep_dup
}.freeze
