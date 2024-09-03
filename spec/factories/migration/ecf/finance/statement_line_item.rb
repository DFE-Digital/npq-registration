# frozen_string_literal: true

FactoryBot.define do
  factory :ecf_migration_statement_line_item, class: "Migration::Ecf::Finance::StatementLineItem" do
    state { :payable }
    participant_declaration { create(:ecf_migration_participant_declaration) }
    statement { create(:ecf_migration_statement) }
  end
end
