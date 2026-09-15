class Power < ApplicationRecord
  has_many :alien_powers, dependent: :destroy
  has_many :aliens, through: :alien_powers
end
