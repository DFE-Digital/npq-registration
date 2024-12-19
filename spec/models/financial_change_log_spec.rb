require "rails_helper"

RSpec.describe FinancialChangeLog, type: :model do
  it "saves the data properly" do
    FinancialChangeLog.log!(description: "Some description", data: { foo: "bar" })

    log = FinancialChangeLog.first
    expect(log.operation_description).to eq("Some description")
    expect(log.data_changes).to eq({"foo" => "bar"})
  end

  it "requires proper operation_description present" do
    expect {
      FinancialChangeLog.log!(description: "", data: { foo: "bar" })
    }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "requires proper operation_description to be at least 5 characters" do
    expect {
      FinancialChangeLog.log!(description: "Foo1", data: { foo: "bar" })
    }.to raise_error(ActiveRecord::RecordInvalid)

    expect {
      FinancialChangeLog.log!(description: "Foo12", data: { foo: "bar" })
    }.not_to raise_error(ActiveRecord::RecordInvalid)
  end

  it "requires data to be present" do
    expect {
      FinancialChangeLog.log!(description: "Foo Bar", data: {})
    }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
