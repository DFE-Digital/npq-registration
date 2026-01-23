class Workplace < ApplicationRecord
  self.table_name = "schools"
  self.primary_key = %i[source_type source_id]

  default_scope { from(Workplace.unioned_table).readonly.order(source_type: :desc) }
  scope :search,
        ->(q) { q.present? ? where("name ILIKE ?", "%#{q}%").or(where(urn: q)) : all }

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
        .order(name: :asc, id: :asc)
        .select(:name, id: :source_id, urn: :urn)
        .select("'#{School.name}' AS source_type")
        .arel
    end

    def local_authority_scope
      LocalAuthority
        .order(name: :asc, id: :asc)
        .select(:name, id: :source_id)
        .select("NULL AS urn")
        .select("'#{LocalAuthority.name}' AS source_type")
        .arel
    end

    def private_childcare_provider_scope
      PrivateChildcareProvider
        .order(provider_name: :asc, id: :asc)
        .select(provider_name: :name, id: :source_id, provider_urn: :urn)
        .select("'#{PrivateChildcareProvider.name}' as source_type")
        .arel
    end
  end
end
