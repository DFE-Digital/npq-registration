# FinancialChangeLog is an easy way to track all financial related data.
#
# While our app has already papertrail, the changing financial data through different CSV files or using different
# data sources need full transparency.
# It provides one place where we can easy track:
# * which process or ticket or dataset changed given data.
# * which records and attributes of those records were changed
# * if record is deleted, the log will still stay in database
# * unlike per model versions, log can be easily searchable
#
# While NPQ is not fully a financial app, the FinancialChangeLog replicate a ledger functionality often being found in
# apps which are financial data are crucial.
class FinancialChangeLog < ApplicationRecord
  ONE_OFF_2326 = "OneOff 2326".freeze

  def self.log!(description:, data:)
    FinancialChangeLog.create!(operation_description: description, data_changes: data)
  end
end