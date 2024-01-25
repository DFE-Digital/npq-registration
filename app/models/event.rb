class Event < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :application, optional: true
  belongs_to :course, optional: true
  belongs_to :lead_provider, optional: true
  belongs_to :school, optional: true
  belongs_to :statement, optional: true
  belongs_to :statement_item, optional: true
  belongs_to :declaration, optional: true

  validates :importance,
            presence: true,
            numericality: {
              only_integer: true,
              in: 1..10,
            }

  validates :subject,
            presence: true,
            length: { maximum: 128 }
end
