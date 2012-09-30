class CreateAvailabilities < ActiveRecord::Migration
  def up
    create_table :availabilities do |t|
      t.integer :property_id
      t.date    :from
      t.date    :to
    end

    add_index :availabilities, :from
    add_index :availabilities, :to
  end

  def down
    drop_table :availabilities
  end
end
