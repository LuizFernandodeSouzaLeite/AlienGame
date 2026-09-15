class CreateAliens < ActiveRecord::Migration[8.1]
  def change
    create_table :aliens do |t|
      t.string :name
      t.integer :age
      # External World Service Planet identifier — deliberately NOT a
      # foreign key. This service does not, and must never, open World
      # Service's database (ADR-003). Existence is validated over HTTP
      # (see app/clients/worlds_client.rb), not by the database.
      t.integer :planet_id, null: false

      t.timestamps
    end

    add_index :aliens, :planet_id
  end
end
