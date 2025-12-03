class AddPolicyDescriptorAndAcceptanceDatesToSchedules < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :schedules, :policy_descriptor, :integer
    add_column :schedules, :acceptance_window_start, :date
    add_column :schedules, :acceptance_window_end, :date

    add_index :schedules, %i[course_group_id acceptance_window_start acceptance_window_end], algorithm: :concurrently
  end
end
