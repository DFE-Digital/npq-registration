class CreateSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :settings do |t|
      t.date :course_start_date

      t.timestamps
    end
  end
end
