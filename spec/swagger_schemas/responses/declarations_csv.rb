DECLARATIONS_CSV_RESPONSE = {
  v1: {
    description: "A list of NPQ enrolments in the Comma Separated Value (CSV) format  ",
    properties: {
      example: {
        type: :array,
        items: { "$ref": "#/components/schemas/DeclarationCsv" },
      },
    },
    example: "id,participant_id,declaration_type,course_identifier,declaration_date,updated_at,state,has_passed,voided,eligible_for_payment\n
    4ccd9937-1a73-4b11-81e6-259f5bd3ca9d,eb8392d6-777e-4568-9c91-3fedb175c74c,started,npq-headship,2024-06-20T00:00:00+00:00,2024-06-20T12:14:37Z,submitted,TODO,false,false\n
    0de68abf-3c43-421d-9f61-ae10b702e700,61ad2b52-de57-4f42-a5f2-0196ba543e8a,started,npq-early-headship-coaching-offer,2024-06-20T00:00:00+00:00,2024-06-20T12:14:37Z,submitted,true,false,false\n",
  },
}.tap { |h|
  h[:v2] = h[:v1].deep_dup
  h[:v2][:example] = "id,participant_id,declaration_type,course_identifier,declaration_date,updated_at,state,has_passed\n
  4ccd9937-1a73-4b11-81e6-259f5bd3ca9d,eb8392d6-777e-4568-9c91-3fedb175c74c,started,npq-headship,2024-06-20T00:00:00+00:00,2024-06-20T12:14:37Z,submitted,TODO,false,false\n
  0de68abf-3c43-421d-9f61-ae10b702e700,61ad2b52-de57-4f42-a5f2-0196ba543e8a,started,npq-early-headship-coaching-offer,2024-06-20T00:00:00+00:00,2024-06-20T12:14:37Z,submitted,true\n"
}.freeze
