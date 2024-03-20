module API
  module V3
    class StatementSerializer < Blueprinter::Base
      class AttributesSerializer < Blueprinter::Base
        exclude :id

        field(:month) { |s, _| Date::MONTHNAMES[s.month] }
        field(:year) { |s, _| s.year.to_s }
        field(:cohort) { |s, _| s.cohort.start_year.to_s }
        field :deadline_date, name: :cut_off_date, datetime_format: "%Y-%m-%d"
        field :payment_date, datetime_format: "%Y-%m-%d"
        field(:paid) { |s, _| s.payment_date.present? }
        field :created_at
        field :updated_at
      end

      identifier :ecf_id, name: :id
      field(:type) { "statement" }

      association :attributes, blueprint: AttributesSerializer do |statement|
        statement
      end
    end
  end
end
