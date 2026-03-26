RSpec.shared_context("with stubbed Teaching Record System person API") do
  let(:user_trn) { "1234567" }

  before do
    trs_response =
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
    stub_request(:get, "#{ENV['TRS_API_URL']}/v3/person")
      .with(query: { "include" => "PreviousNames" })
      .to_return(status: 200, body: trs_response.to_json)
  end
end
