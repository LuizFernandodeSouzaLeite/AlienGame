# The explicit v1 Power representation — see contracts/powers/v1/.
# Deliberately not `render json: @power`: the API contract is a promise to
# other services, not an accident of whatever columns ActiveRecord happens
# to have today.
class PowerSerializer
  def self.call(power)
    {
      id: power.id,
      name: power.name,
      created_at: power.created_at,
      updated_at: power.updated_at
    }
  end
end
