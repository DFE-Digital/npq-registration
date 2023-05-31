class CreateGeoLocalAuthorities < ActiveRecord::Migration[6.1]
  def change
    create_table :geo_local_authorities do |t|
      t.string :name
      t.geometry :geometry, srid: 27_700

      t.timestamps
    end

    add_index :geo_local_authorities, :geometry, using: :gist
  end
end
