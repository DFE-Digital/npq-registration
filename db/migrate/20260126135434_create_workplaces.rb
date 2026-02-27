class CreateWorkplaces < ActiveRecord::Migration[8.0]
  def change
    create_view :workplaces
  end
end
