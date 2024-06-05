class CreateApplicationStatusesEnum < ActiveRecord::Migration[7.1]
  def change
    create_enum :application_statuses, %w[active deferred withdrawn]
  end
end
