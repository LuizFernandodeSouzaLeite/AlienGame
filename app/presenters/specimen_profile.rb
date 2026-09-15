class SpecimenProfile
  # Bumped whenever the derivation order/logic changes in a way that would
  # reshuffle existing specimens. Not persisted — purely so a human auditing
  # a screenshot knows which generator produced it.
  GENERATOR_VERSION = 2

  ARCHETYPES = %i[ humanoid tentacular crystalline insectoid amorphous aberrant ].freeze
  # Each archetype's plausible ways of occupying the tank. Locomotion is
  # picked from the archetype's own pool so it stays anatomically coherent
  # (a crystal doesn't "swim"), while still varying specimen to specimen.
  LOCOMOTION_POOL = {
    humanoid: %i[ suspended free_swimming suspended ],
    tentacular: %i[ free_swimming coiling free_swimming free_swimming ],
    crystalline: %i[ floating stationary floating ],
    insectoid: %i[ crawling climbing bottom_dwelling crawling ],
    amorphous: %i[ bottom_dwelling surface_adherent mass_spread ],
    aberrant: %i[ orbital radial_drift free_swimming ]
  }.freeze
  EXPRESSIVENESS_POOL = {
    humanoid: %i[ high high medium ],
    tentacular: %i[ medium low high ],
    crystalline: %i[ low non_facial ],
    insectoid: %i[ medium high ],
    amorphous: %i[ low non_facial non_facial ],
    aberrant: %i[ non_facial low ]
  }.freeze
  SCALE_CLASSES = %i[ tiny small small medium medium medium large long ].freeze
  MATERIALS = %i[ smooth_skin porous_membrane chitin crystalline_surface translucent_tissue gelatinous_mass ].freeze
  PALETTES = [
    { name: "bone", base: "#b7aa91", shadow: "#554d42", light: "#e8dcc4", glow: "#d7c69a" },
    { name: "rust", base: "#9f513b", shadow: "#492a27", light: "#d8875d", glow: "#f1a36d" },
    { name: "olive", base: "#71804a", shadow: "#303c2d", light: "#abb76e", glow: "#cbd879" },
    { name: "deep-green", base: "#326558", shadow: "#172f2b", light: "#67a889", glow: "#8bddb0" },
    { name: "abyss-blue", base: "#385f82", shadow: "#182b45", light: "#6f9fc0", glow: "#8bd1e4" },
    { name: "violet", base: "#6f507f", shadow: "#30263d", light: "#a987b4", glow: "#d5a8dd" },
    { name: "pearl", base: "#9ca3a0", shadow: "#3c4647", light: "#e0e1d9", glow: "#d9fff3" },
    { name: "dark-red", base: "#743635", shadow: "#301d23", light: "#b45d50", glow: "#ef7d63" }
  ].freeze
  TRAITS = %i[ aggressive curious playful timid passive docile defensive territorial ].freeze

  attr_reader :seed, :archetype, :secondary_archetype, :morphology, :behavior,
    :primary_trait, :secondary_trait, :activity_band, :palette, :impact_threshold,
    :scale_class, :locomotion, :materiality, :expressiveness

  def initialize(id)
    @seed = id.to_i
    morphology_rng = Random.new(@seed ^ 0x58E4_41)
    behavior_rng = Random.new(@seed ^ 0xB10_109)
    @archetype = ARCHETYPES[@seed % ARCHETYPES.length]
    @secondary_archetype = (ARCHETYPES - [ @archetype ])[morphology_rng.rand(ARCHETYPES.length - 1)]
    @morphology = build_morphology(morphology_rng).freeze
    @behavior = build_behavior(behavior_rng).freeze
    ranked_traits = TRAITS.sort_by { |trait| -trait_score(trait) }
    @primary_trait = ranked_traits.first
    @secondary_trait = ranked_traits.drop(1).find { |trait| compatible_secondary?(trait) } || ranked_traits.second
    @activity_band = band(@behavior[:activity])
    @palette = PALETTES[morphology_rng.rand(PALETTES.length)].freeze

    # Independent subseed channels: each new presentation axis gets its own
    # Random stream (seed ^ distinct constant) so adding a trait here never
    # reshuffles archetype/behavior/palette derivation for existing specimens.
    @scale_class = SCALE_CLASSES[Random.new(@seed ^ 0x5CA1_E5).rand(SCALE_CLASSES.length)]
    @locomotion = LOCOMOTION_POOL.fetch(@archetype).then { |pool| pool[Random.new(@seed ^ 0x10C0_A1).rand(pool.length)] }
    @materiality = MATERIALS[Random.new(@seed ^ 0x7A11_A5).rand(MATERIALS.length)]
    @expressiveness = EXPRESSIVENESS_POOL.fetch(@archetype).then { |pool| pool[Random.new(@seed ^ 0x0E_E5C1).rand(pool.length)] }

    @impact_threshold = (10.0 + behavior_rng.rand * 4.0).round(2)
    freeze
  end

  def containment_mode = locomotion

  def roams?
    %i[ free_swimming floating orbital radial_drift ].include?(locomotion)
  end

  def aggressive?
    primary_trait == :aggressive || behavior[:aggression] >= 72
  end

  def primary_label = primary_trait.to_s.upcase
  def secondary_label = secondary_trait.to_s.upcase

  def body_class
    [ "specimen--#{archetype}", "specimen--#{secondary_archetype}", "specimen--#{palette[:name]}" ].join(" ")
  end

  private
    def build_morphology(rng)
      {
        symmetry: rng.rand(22..100), head_count: rng.rand(1..3), eye_count: rng.rand(0..6),
        limb_count: rng.rand(2..8), appendage_count: rng.rand(2..9), elongation: rng.rand(35..100),
        body_width: rng.rand(38..94), segment_count: rng.rand(3..9), transparency: rng.rand(0..100),
        bioluminescence: rng.rand(0..100), membrane: rng.rand < 0.38, shell: rng.rand < 0.42, tail: rng.rand < 0.46
      }
    end

    def build_behavior(rng)
      {
        aggression: rng.rand(0..100), curiosity: rng.rand(0..100), activity: rng.rand(0..100),
        fear: rng.rand(0..100), playfulness: rng.rand(0..100), social_response: rng.rand(0..100),
        territoriality: rng.rand(0..100), reactivity: rng.rand(0..100)
      }
    end

    def trait_score(trait)
      b = behavior
      {
        aggressive: b[:aggression] * 1.25 + b[:reactivity] * 0.45 + b[:territoriality] * 0.25 - b[:fear] * 0.2,
        curious: b[:curiosity] * 1.35 + b[:reactivity] * 0.25 + b[:activity] * 0.2,
        playful: b[:playfulness] * 1.3 + b[:curiosity] * 0.35 + b[:activity] * 0.25,
        timid: b[:fear] * 1.3 + (100 - b[:aggression]) * 0.35 + b[:reactivity] * 0.2,
        passive: (100 - b[:aggression]) * 0.55 + (100 - b[:reactivity]) * 0.5 + (100 - b[:activity]) * 0.55,
        docile: (100 - b[:aggression]) * 0.65 + (100 - b[:fear]) * 0.35 + b[:social_response] * 0.45,
        defensive: b[:fear] * 0.65 + b[:territoriality] * 0.55 + b[:aggression] * 0.35,
        territorial: b[:territoriality] * 1.2 + b[:aggression] * 0.35 + b[:reactivity] * 0.25
      }.fetch(trait)
    end

    def compatible_secondary?(trait)
      trait != primary_trait && !([ primary_trait, trait ].sort == %i[ aggressive docile ])
    end

    def band(value)
      return "LOW" if value < 34
      return "HIGH" if value > 67

      "MODERATE"
    end
end
