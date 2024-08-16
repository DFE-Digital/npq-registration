class ChangeApplicationsKindOfNurseryToEnum < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      ALTER TABLE applications
      ALTER COLUMN kind_of_nursery TYPE kind_of_nurseries
      USING kind_of_nursery::kind_of_nurseries
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE applications
      ALTER COLUMN kind_of_nursery TYPE text
    SQL
  end
end
