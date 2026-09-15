class CreateAliens < ActiveRecord::Migration[8.1]
  def change
    create_table :aliens do |t|
      t.string :name
      t.string :string
      t.integer :age

      t.timestamps
    end
  end
end
