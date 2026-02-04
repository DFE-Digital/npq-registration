class Workplace < ApplicationRecord
  self.primary_key = %i[source_type source_id]
  belongs_to :source, polymorphic: true

  default_scope { order(source_type: :desc) }

  scope :search, lambda { |q|
    next all if q.blank?

    where("name ILIKE ?", "%#{sanitize_sql_like(q)}%").or(where(urn: q))
  }

  def readonly? = true
end
