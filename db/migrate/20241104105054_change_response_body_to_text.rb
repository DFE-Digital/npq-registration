class ChangeResponseBodyToText < ActiveRecord::Migration[7.1]
  def up
    change_column :response_comparisons, :ecf_response_body, :text
    change_column :response_comparisons, :npq_response_body, :text
  end

  def down
    change_column :response_comparisons, :ecf_response_body, :string
    change_column :response_comparisons, :npq_response_body, :string
  end
end
