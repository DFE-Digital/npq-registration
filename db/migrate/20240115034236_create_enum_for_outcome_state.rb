class CreateEnumForOutcomeState < ActiveRecord::Migration[7.1]
  def change
    create_enum :outcome_states, %w[passed failed voided]
  end
end
