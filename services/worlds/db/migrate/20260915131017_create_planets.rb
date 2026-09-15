class CreatePlanets < ActiveRecord::Migration[8.1]
  def change
    create_table :planets do |t|
      t.string :name

      t.timestamps
    end
  end
end
