require "test_helper"

# Phase 7 (SOA migration) evidence: Power's current delete semantics, so
# the future distributed equivalent (Power Service deleting a Power
# without being able to touch Alien Service's alien_powers table) can be
# designed against real, proven behavior instead of assumption. See
# docs/architecture/MIGRATION_PLAN.md's Phase 7 record.
class PowerAlienPowersCouplingTest < ActiveSupport::TestCase
  test "alien_powers.power_id and .alien_id have real, enforced database foreign keys" do
    foreign_keys = ActiveRecord::Base.connection.foreign_keys("alien_powers")

    power_fk = foreign_keys.find { |k| k.column == "power_id" }
    alien_fk = foreign_keys.find { |k| k.column == "alien_id" }

    refute_nil power_fk, "expected a real FK on alien_powers.power_id"
    assert_equal "powers", power_fk.to_table
    refute_nil alien_fk, "expected a real FK on alien_powers.alien_id"
    assert_equal "aliens", alien_fk.to_table
  end

  test "alien_powers.power_id and .alien_id are NOT NULL and indexed" do
    assert_not AlienPower.columns_hash["power_id"].null
    assert_not AlienPower.columns_hash["alien_id"].null
    assert ActiveRecord::Base.connection.index_exists?(:alien_powers, :power_id)
    assert ActiveRecord::Base.connection.index_exists?(:alien_powers, :alien_id)
  end

  test "Power#destroy cascades to its alien_powers rows today (dependent: :destroy), leaving Aliens untouched" do
    power = powers(:one)
    alien = aliens(:one)
    assert AlienPower.exists?(alien_id: alien.id, power_id: power.id)

    assert_difference("AlienPower.count", -1) do
      assert_no_difference("Alien.count") do
        power.destroy!
      end
    end

    assert Alien.exists?(alien.id), "destroying a Power must not touch Alien rows"
    assert_not AlienPower.exists?(alien_id: alien.id, power_id: power.id)
  end

  test "an alien_powers row cannot reference a nonexistent power_id (DB FK), same mechanism proven for Planet in Phase 6" do
    alien_power = AlienPower.new(alien_id: aliens(:one).id, power_id: 999_999)

    assert_raises(ActiveRecord::InvalidForeignKey) { alien_power.save!(validate: false) }
  end

  test "an Alien can never be assigned a Power that exists only in Power Service (Phase 8 remote-only-Power scenario)" do
    # Mirrors Phase 6's Planet finding exactly: if Power Service creates a
    # Power root doesn't have locally, no root Alien can ever reference it
    # — not through validation, and not even bypassing validation (DB FK).
    power_service_only_id = Power.maximum(:id).to_i + 1
    assert_not Power.exists?(power_service_only_id), "test setup assumption broken"

    alien_power = AlienPower.new(alien_id: aliens(:one).id, power_id: power_service_only_id)
    assert_not alien_power.valid?
    assert_includes alien_power.errors.full_messages, "Power must exist"
    assert_raises(ActiveRecord::InvalidForeignKey) { alien_power.save!(validate: false) }
  end
end
