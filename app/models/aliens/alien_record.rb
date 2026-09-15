module Aliens
  # A read-only representation of an Alien's durable domain data, as
  # returned by Alien Service's /api/v1/aliens contract (see
  # contracts/aliens/v1/README.md). NOT ActiveRecord: no save/update/
  # destroy. Deliberately carries ONLY durable fields — no transient tank
  # position, behavioral state, scanner phase, or anything else that
  # lives only in the browser session (see Aliens::ShadowAlienVerifier
  # for why those are never compared).
  AlienRecord = Data.define(:id, :name, :age, :planet_id, :power_ids)
end
