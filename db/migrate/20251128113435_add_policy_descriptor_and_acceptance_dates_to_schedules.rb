class AddPolicyDescriptorAndAcceptanceDatesToSchedules < ActiveRecord::Migration[7.2]
  def change
    add_column :schedules, :policy_descriptor, :integer
    add_column :schedules, :acceptance_window_start, :date
    add_column :schedules, :acceptance_window_end, :date
  end
end
