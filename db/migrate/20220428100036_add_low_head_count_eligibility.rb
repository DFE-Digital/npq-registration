class AddLowHeadCountEligibility < ActiveRecord::Migration[6.1]
  def change
    add_column :applications, :low_head_count_eligibility, :boolean, default: false
  end
end
