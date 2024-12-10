# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Voided declarations", type: :feature do
  include Helpers::AdminLogin

  let(:statement) { create(:statement) }
  let(:other_statement) { create(:statement) }

  let!(:eligible_declaration) { create(:declaration, :eligible, statement:) }
  let!(:voided_declaration) { create(:declaration, :voided, statement:) }
  let!(:other_voided_declaration) { create(:declaration, :voided, statement: other_statement) }

  before { sign_in_as(create(:admin)) }

  scenario "index for a paid statement" do
    visit npq_separation_admin_finance_voided_index_path(statement)

    expect(page).to have_css("td:nth-child(1)", text: voided_declaration.id)
    expect(page).to have_css("td:nth-child(2)", text: voided_declaration.user.id)
    expect(page).to have_css("td:nth-child(3)", text: voided_declaration.declaration_type)
    expect(page).to have_css("td:nth-child(4)", text: voided_declaration.course.name)

    expect(page).not_to have_css("td:nth-child(1)", text: eligible_declaration.id)
    expect(page).not_to have_css("td:nth-child(1)", text: other_voided_declaration.id)
  end
end
