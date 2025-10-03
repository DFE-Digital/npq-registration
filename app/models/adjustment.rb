class Adjustment < ApplicationRecord
  belongs_to :statement

  validates :description, presence: true
  validates :amount, presence: true
  validates :amount, numericality: { other_than: 0 }, if: :amount
  validates :amount, format: { with: /\A-?\d+\.\d*?\z/ }, if: -> { amount.present? }
end
