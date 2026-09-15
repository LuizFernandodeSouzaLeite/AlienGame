class Alien < ApplicationRecord
    belongs_to :planet

    has_many :alien_powers, dependent: :destroy
    has_many :powers, through: :alien_powers

    validates_presence_of :name
end
