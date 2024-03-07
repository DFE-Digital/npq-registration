module API
  module V3
    class StatementSerializer < Blueprinter::Base
      identifier :id

      field :month
      field :year
      field(:cohort) { |s, _| s.cohort.start_year }
      field :deadline_date, name: :cut_off_date, datetime_format: "%Y-%m-%d"
      field :payment_date, datetime_format: "%Y-%m-%d"
      field :created_at
      field :updated_at

      field(:paid) { |s, _| s.payment_date.present? }
    end
  end
end
