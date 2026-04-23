class AddCourseCohortProviderTables < ActiveRecord::Migration[8.0]
  def change
    create_table :course_cohorts do |t|
      t.references :course, null: false, foreign_key: true
      t.references :cohort, null: false, foreign_key: true
      t.timestamps
    end
    add_index :course_cohorts, %i[course_id cohort_id], unique: true

    create_table :course_cohort_providers do |t|
      t.references :course_cohort, null: false, foreign_key: true
      t.references :lead_provider, null: false, foreign_key: true
      t.timestamps
    end
    add_index :course_cohort_providers, %i[course_cohort_id lead_provider_id], unique: true
  end
end
