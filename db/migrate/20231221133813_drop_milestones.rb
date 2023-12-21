class DropMilestones < ActiveRecord::Migration[7.0]
  def up
    drop_table :milestones
  end
end
