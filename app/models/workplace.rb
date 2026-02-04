class Workplace < ApplicationRecord
  self.table_name = "schools"
  self.primary_key = %i[source_type source_id]

  default_scope { readonly.from(unioned_table).order(source_type: :desc) }

  scope :search, lambda { |q|
    next all if q.blank?

    where("name ILIKE ?", "%#{sanitize_sql_like(q)}%").or(where(urn: q))
  }

  belongs_to :source, polymorphic: true

  class << self
    def unioned_table
      Arel::Nodes::UnionAll.new(
        school_scope,
        Arel::Nodes::UnionAll.new(
          local_authority_scope,
          private_childcare_provider_scope,
        ),
      ).as(table_name)
    end

  private

    def school_scope
      School
        .select(:name, id: :source_id, urn: :urn)
        .select("'#{School.name}' AS source_type")
        .arel
    end

    def local_authority_scope
      LocalAuthority
        .select(:name, id: :source_id)
        .select("NULL AS urn")
        .select("'#{LocalAuthority.name}' AS source_type")
        .arel
    end

    def private_childcare_provider_scope
      PrivateChildcareProvider
        .select(provider_name: :name, id: :source_id, provider_urn: :urn)
        .select("'#{PrivateChildcareProvider.name}' as source_type")
        .arel
    end
  end
end
