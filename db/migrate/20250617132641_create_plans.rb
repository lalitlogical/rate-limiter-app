class CreatePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :plans do |t|
      t.string :name
      t.integer :limit
      t.integer :burst_capacity
      t.integer :token_rate

      t.integer :bucket_capacity
      t.integer :leak_rate

      t.timestamps
    end
  end
end
