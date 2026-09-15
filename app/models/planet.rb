class Planet < ApplicationRecord
  has_many :aliens, dependent: :destroy
end
