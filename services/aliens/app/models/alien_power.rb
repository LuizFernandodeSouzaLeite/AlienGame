# A join row owned entirely by Alien Service (ADR-002): "this Alien
# possesses this Power". `power_id` is a plain external Power Service
# identifier — no local Power model exists here, and none should.
class AlienPower < ApplicationRecord
  belongs_to :alien
end
