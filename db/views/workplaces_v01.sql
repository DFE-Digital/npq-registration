(
  SELECT
    "schools"."name",
    "schools"."id" AS "source_id",
    "schools"."urn" AS "urn",
    'School' AS source_type
  FROM "schools"
)

UNION ALL

(
  SELECT
    "local_authorities"."name",
    "local_authorities"."id" AS "source_id",
    NULL AS urn,
    'LocalAuthority' AS source_type
  FROM "local_authorities"
)

UNION ALL

(
  SELECT
    "private_childcare_providers"."provider_name" AS "name",
    "private_childcare_providers"."id" AS "source_id",
    "private_childcare_providers"."provider_urn" AS "urn",
    'PrivateChildcareProvider' as source_type
  FROM "private_childcare_providers"
  WHERE
    "private_childcare_providers"."disabled_at" IS NULL
)
