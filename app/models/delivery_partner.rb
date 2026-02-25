class DeliveryPartner < ApplicationRecord
  scope :name_similar_to, ->(name) { wildcard_search(name).or(levenshtein_name_search(name)).where.not(name:) }
  scope :levenshtein_name_search, ->(name) { where("levenshtein(name, ?) <= 4", name) }
  scope :contains, ->(name) { where("name ILIKE ?", "%#{name}%") }
  scope :begins_with, ->(name) { where("name ILIKE ?", "#{name}%") }

  has_many :delivery_partnerships
  has_many :lead_providers, through: :delivery_partnerships
  has_many :cohorts, through: :delivery_partnerships

  accepts_nested_attributes_for :delivery_partnerships, allow_destroy: true

  validates :ecf_id, uniqueness: { case_sensitive: false }
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def self.wildcard_search(name)
    name_begins_with_the = name.match(/^The (.*)/)
    scope = if name_begins_with_the
              begins_with("The #{name.split.second}").or(begins_with(name_begins_with_the[1].split.first))
            else
              begins_with(name.split.first).or(begins_with("The #{name.split.first}"))
            end
    scope.or(contains(name))
  end

  def declarations
    Declaration.for_delivery_partners(self)
  end

  def cohorts_for_lead_provider(lead_provider)
    Cohort.includes(:delivery_partnerships).where(delivery_partnerships: { lead_provider:, delivery_partner: self })
  end
end
