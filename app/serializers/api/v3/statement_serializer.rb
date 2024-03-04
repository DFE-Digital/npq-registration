module API
  module V3
    class StatementSerializer < Blueprinter::Base
      identifier :id

      field :month
      field :year
      field(:type) { 'npq' }
      field :cohort_id, name: :cohort
      field(:deadline_date, name: :cut_off_date) { |s, _| s.deadline_date.strftime("%Y-%m-%d") }
      field(:payment_date) { |s, _| s.payment_date&.strftime("%Y-%m-%d") }
      field(:paid) { |s, _| s.payment_date.present? }
      field(:created_at) { |s, _| s.created_at.iso8601 }
      field(:updated_at) { |s, _| s.updated_at.iso8601 }
    end
  end
end
