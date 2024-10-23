class AddPageToResponseComparisons < ActiveRecord::Migration[7.1]
  def change
    add_column :response_comparisons, :page, :integer, null: true
  end
end
