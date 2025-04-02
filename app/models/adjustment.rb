class Adjustment < ApplicationRecord
  belongs_to :statement

  validates :description, presence: true
  validates :amount, presence: true
  validates :amount, numericality: { greater_than: 0 }, if: :amount
  validates :amount, format: { with: /\A[0-9]*\z/ }, if: -> { amount.present? }
end
