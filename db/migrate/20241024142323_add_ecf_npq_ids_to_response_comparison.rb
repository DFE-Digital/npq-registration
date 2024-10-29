class AddEcfNpqIdsToResponseComparison < ActiveRecord::Migration[7.1]
  def change
    add_column :response_comparisons, :npq_response_body_ids, :string, array: true, default: []
    add_column :response_comparisons, :ecf_response_body_ids, :string, array: true, default: []
  end
end
