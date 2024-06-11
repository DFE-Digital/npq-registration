ENROLMENTS_CSV_RESPONSE = {
  v2: {
    description: "A list of NPQ enrolments in the Comma Separated Value (CSV) format  ",
    properties: {
      example: {
        type: :array,
        items: { "$ref": "#/components/schemas/EnrolmentCsv" },
      },
    },
    example: "participant_id,course_identifier,schedule_identifier,cohort,npq_application_id,eligible_for_funding,training_status,school_urn,funded_place\n
    52a606ba-4e49-4dab-aa11-42e1e9274884,npq-senior-leadership,npq-ehco-june,2022,8e788f3c-4eac-4bb3-876d-b7b701fcdbd3,true,active,945562,true\n
    e6112b6f-e9c8-40ad-8e5a-3f74dc74d7fd,npq-leading-teaching,npq-leadership-autumn,2022,6feecd44-196a-4203-9fcd-207fb8ddc4eb,true,active,102561,true\n",
  },
}.freeze
