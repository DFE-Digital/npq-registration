class ChangeSchoolsToEducationalInstitution < ActiveRecord::Migration[6.1]
  def up
    add_column :schools, :type, :string, default: :school, null: false

    rename_table :schools, :educational_institutions

    change_column_default :educational_institutions, :type, nil
  end

  def down
    rename_table :educational_institutions, :schools

    remove_column :schools, :type
  end
end
