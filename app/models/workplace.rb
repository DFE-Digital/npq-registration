class Workplace < ApplicationRecord
  self.primary_key = %i[source_type source_id]
  belongs_to :source, polymorphic: true

  default_scope { order(source_type: :desc, name: :asc, source_id: :asc) }

  scope :search, lambda { |q|
    q.present? ? where("name ILIKE ?", "%#{q}%").or(where(urn: q)) : all
  }

  def readonly? = true
end
