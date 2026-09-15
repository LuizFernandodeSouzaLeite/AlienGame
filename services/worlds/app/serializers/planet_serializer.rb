# The explicit v1 Planet representation — see contracts/worlds/v1/.
# Deliberately not `render json: @planet`: the API contract is a promise to
# other services, not an accident of whatever columns ActiveRecord happens
# to have today.
class PlanetSerializer
  def self.call(planet)
    {
      id: planet.id,
      name: planet.name,
      created_at: planet.created_at,
      updated_at: planet.updated_at
    }
  end
end
