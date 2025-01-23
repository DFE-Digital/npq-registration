module Statements
  class BulkCreator
    class StatementRow
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :year, :integer
      attribute :month, :integer
      attribute :deadline_date, :date
      attribute :payment_date, :date
      attribute :output_fee, :boolean, default: false

      validates :year, inclusion: { in: 2020..2040, message: "must be between 2020 and 2040" }
      validates :month, inclusion: { in: 1..12, message: "must be between 1 and 12" }
      validates :deadline_date, presence: { message: "must be a date (e.g. YYYY-MM-DD)" }
      validates :payment_date, presence: { message: "must be a date (e.g. YYYY-MM-DD)" }

      def self.example_csv
        <<~CSV.strip
          year,month,deadline_date,payment_date,output_fee
          2025,2,2024-12-25,2025-01-26,true
          2025,3,2025-01-26,2025-02-27,false
          2025,4,2025-02-24,2025-03-25,false
        CSV
      end
    end
  end
end
