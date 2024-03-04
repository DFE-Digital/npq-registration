# spec/views/api/v3/statements/_statement.json.jbuilder_spec.rb

require 'rails_helper'

RSpec.describe 'api/v3/statements/show.json.jbuilder', type: :view do
  let(:cohort) { create(:cohort) }
  let(:statement) { create(:statement, cohort: cohort) }

  before do
    assign(:statement, statement)

    render
  end

  let(:parsed_response) { JSON.parse(rendered) }

  it 'renders statement' do
    puts parsed_response.inspect
    expect(parsed_response['id']).to eq(statement.id)
    expect(parsed_response['month']).to eq(statement.month)
    expect(parsed_response['year']).to eq(statement.year)
    expect(parsed_response['cohort']).to eq(statement.cohort.start_year)
    expect(parsed_response['cut_off_date']).to eq(statement.deadline_date.strftime("%Y-%m-%d"))
    expect(parsed_response['payment_date']).to eq(statement.payment_date.strftime("%Y-%m-%d")) if statement.payment_date
    expect(parsed_response['created_at']).to eq(statement.created_at.iso8601)
    expect(parsed_response['updated_at']).to eq(statement.updated_at.iso8601)
    expect(parsed_response['paid']).to eq(statement.payment_date.present?)
    expect(parsed_response['type']).to eq('npq')
  end
end