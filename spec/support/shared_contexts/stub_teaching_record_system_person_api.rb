RSpec.shared_context("with stubbed Teaching Record System person API") do |stub: true|
  let(:user_trn) { "1234567" }
  let(:trs_response) do
    {
      "trn" => user_trn,
      "firstName" => "John",
      "middleName" => "",
      "lastName" => "Doe",
      "dateOfBirth" => "1980-01-01",
      "nationalInsuranceNumber" => "QQ123456A",
      "previousNames" => [
        { "firstName" => "Jane", "middleName" => "", "lastName" => "Doe" },
      ],
    }
  end

  def stub_trs
    stub_request(:get, "#{ENV["TRS_API_URL"]}/v3/person")
      .with(query: { "include" => "PreviousNames" })
      .to_return(status: 200, body: trs_response.to_json)
  end

  before do
    stub_trs if stub
  end
end

RSpec.shared_context("with stubbed missing Teaching Record System person record") do
  before do
    stub_request(:get, "#{ENV["TRS_API_URL"]}/v3/person")
      .with(query: { "include" => "PreviousNames" })
      .to_return(status: 403, body: nil)
  end
end
