# Reproduces root's current local Alien validations exactly (name
# presence only — see docs/architecture/MIGRATION_PLAN.md's Phase 9
# compatibility table). Deliberately does NOT have `belongs_to :planet`:
# Planet lives in World Service's database, not here (ADR-003) —
# `planet_id` is a plain external identifier, validated over HTTP at the
# controller layer (see Api::V1::AliensController), not via a hidden
# ActiveRecord network callback.
class Alien < ApplicationRecord
  has_many :alien_powers, dependent: :destroy

  validates_presence_of :name
end
