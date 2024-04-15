class ChangeApplicationsFundingChoiceToEnum < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      ALTER TABLE applications
      ALTER COLUMN funding_choice TYPE funding_choices
      USING funding_choice::funding_choices
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE applications
      ALTER COLUMN funding_choice TYPE text
    SQL
  end
end
