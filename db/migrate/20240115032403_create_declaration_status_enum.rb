class CreateDeclarationStatusEnum < ActiveRecord::Migration[7.1]
  def up
    create_enum :declaration_status_enum, %w[eligible payable paid voided ineligible awaiting_clawback clawed_back]
  end

  def down
    drop_enum :declaration_status_enum
  end
end
