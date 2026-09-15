class CreateAlienPowers < ActiveRecord::Migration[8.1]
  def change
    create_table :alien_powers do |t|
      # Local FK: alien_powers and aliens live in the same database here,
      # so a real foreign key is correct and safe (ADR-003).
      t.references :alien, null: false, foreign_key: true

      # External Power Service Power identifier — deliberately NOT a
      # foreign key. This service does not, and must never, open Power
      # Service's database (ADR-002/ADR-003). Existence is validated over
      # HTTP (see app/clients/powers_client.rb), not by the database.
      t.integer :power_id, null: false

      t.timestamps
    end

    add_index :alien_powers, :power_id
  end
end
