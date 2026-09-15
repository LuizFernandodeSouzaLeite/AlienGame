module AliensHelper
  def specimen_profile(alien)
    @specimen_profiles ||= {}
    @specimen_profiles[alien.id] ||= SpecimenProfile.new(alien.id)
  end

  def species_signature(alien, capture: false)
    profile = specimen_profile(alien)
    rng = Random.new(profile.seed ^ 0xA11_E05)
    gradient_id = "tissue-#{profile.seed}-#{capture ? 'capture' : 'live'}"
    anatomy = send("specimen_#{profile.archetype}", profile, rng)
    palette = profile.palette
    classes = [ "signature", profile.body_class, ("signature--capture" if capture) ].compact.join(" ")
    style = "--bio-base:#{palette[:base]};--bio-shadow:#{palette[:shadow]};--bio-light:#{palette[:light]};--bio-glow:#{palette[:glow]}"

    <<~SVG.html_safe
      <svg class="#{classes}" style="#{style}" viewBox="0 0 220 300" aria-hidden="true">
        <defs><linearGradient id="#{gradient_id}" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#{palette[:light]}"/><stop offset=".48" stop-color="#{palette[:base]}"/><stop offset="1" stop-color="#{palette[:shadow]}"/></linearGradient></defs>
        <g class="organism-shadow" transform="translate(5 8)">#{anatomy.gsub("url(#tissue)", "url(##{gradient_id})")}</g>
        <g class="organism-body">#{anatomy.gsub("url(#tissue)", "url(##{gradient_id})")}</g>
        <g class="bio-scan-layer"><path class="anatomical-path" d="M42 148C68 118 77 61 111 44c35 17 40 73 68 104-24 39-38 67-68 101-32-32-48-66-69-101Z"/>#{tracking_nodes(profile, rng)}<path class="section-marker" d="M22 95h30m-30 105h34M168 95h30m-34 105h34"/></g>
      </svg>
    SVG
  end

  def species_archetype(alien)
    specimen_profile(alien).archetype
  end

  private
    def specimen_humanoid(profile, _rng)
      head_width = 34 + profile.morphology[:body_width] / 6
      eyes = [ 88, 132 ].first([ profile.morphology[:eye_count], 2 ].max).map do |x|
        %(<ellipse class="anatomy-eye reactive-organ" cx="#{x}" cy="82" rx="7" ry="11"/>)
      end.join
      <<~SVG
        <path class="anatomy-surface anatomy-torso" d="M72 128Q110 108 148 128l19 89-31 27-26-16-27 16-31-27 20-89Z" fill="url(#tissue)"/>
        <ellipse class="anatomy-surface anatomy-head" cx="110" cy="79" rx="#{head_width}" ry="55" fill="url(#tissue)"/>
        <path class="anatomy-limb anatomy-arm-l" d="M73 142Q42 165 38 218t25 46"/><path class="anatomy-limb anatomy-arm-r" d="M147 142q31 23 35 76t-25 46"/>
        <path class="anatomy-limb anatomy-leg-l" d="M93 222 80 286"/><path class="anatomy-limb anatomy-leg-r" d="m127 222 13 64"/>
        #{eyes}<path class="bio-vein" d="M110 125v87m-29-59 58 35M77 72q33 23 66 0"/><ellipse class="bio-core" cx="110" cy="172" rx="12" ry="21"/>
      SVG
    end

    def specimen_tentacular(profile, rng)
      count = profile.morphology[:appendage_count]
      tentacles = count.times.map do |index|
        x = 58 + index * (104.0 / [ count - 1, 1 ].max)
        bend = rng.rand(-35..35)
        %(<path class="anatomy-limb anatomy-tentacle" style="--part:#{index}" d="M#{x.round} 168Q#{x + bend} 220 #{x + bend / 2} 292"/>)
      end.join
      <<~SVG
        #{tentacles}<path class="anatomy-surface anatomy-mantle" d="M53 151Q46 59 110 25q64 34 57 126c-18 32-96 32-114 0Z" fill="url(#tissue)"/>
        <path class="anatomy-membrane" d="M64 142q46-38 92 0-10 35-46 36t-46-36Z"/>
        <circle class="anatomy-eye reactive-organ" cx="88" cy="109" r="8"/><circle class="anatomy-eye reactive-organ" cx="132" cy="109" r="8"/>
        <path class="bio-vein" d="M110 39v108M76 68q34 31 68 0"/><circle class="bio-core" cx="110" cy="89" r="17"/>
      SVG
    end

    def specimen_crystalline(_profile, rng)
      facets = (0...7).map do |index|
        x = 55 + rng.rand(0..110); y = 54 + rng.rand(0..170)
        %(<path class="crystal-growth" style="--part:#{index}" d="M110 168 #{x} #{y} #{x + rng.rand(-18..18)} #{y + rng.rand(24..60)}Z"/>)
      end.join
      <<~SVG
        <path class="anatomy-surface crystal-shell" d="m110 14 49 58 35 91-46 101-38 24-47-31-37-94 34-96 50-53Z" fill="url(#tissue)"/>
        #{facets}<path class="bio-vein" d="m110 14v274M60 67l88 197M159 72 63 257"/><polygon class="bio-core" points="110,112 139,158 110,207 80,159"/>
      SVG
    end

    def specimen_insectoid(_profile, rng)
      legs = [ 115, 154, 194 ].flat_map.with_index do |y, index|
        reach = 35 + rng.rand(0..22)
        [ %(<path class="anatomy-limb anatomy-leg-l" style="--part:#{index}" d="M88 #{y} 52 #{y + 12} #{45 - reach} #{y + 48}"/>),
          %(<path class="anatomy-limb anatomy-leg-r" style="--part:#{index}" d="M132 #{y} 168 #{y + 12} #{175 + reach} #{y + 48}"/>) ]
      end.join
      <<~SVG
        #{legs}<ellipse class="anatomy-surface anatomy-abdomen" cx="110" cy="205" rx="45" ry="77" fill="url(#tissue)"/>
        <path class="anatomy-surface anatomy-thorax" d="M71 103q39-34 78 0l-14 69H85l-14-69Z" fill="url(#tissue)"/><path class="anatomy-surface anatomy-head" d="M76 79 91 30h38l15 49-34 29Z" fill="url(#tissue)"/>
        <path class="anatomy-antenna" d="M94 37Q66 5 49 18M126 37q28-32 45-19"/><circle class="anatomy-eye reactive-organ" cx="94" cy="66" r="8"/><circle class="anatomy-eye reactive-organ" cx="126" cy="66" r="8"/>
        <path class="segment-lines" d="M72 183h76M68 211h84M75 240h70"/><ellipse class="bio-core" cx="110" cy="145" rx="13" ry="24"/>
      SVG
    end

    def specimen_amorphous(_profile, _rng)
      <<~SVG
        <path class="anatomy-surface anatomy-mass" d="M43 247C12 211 43 180 39 143 34 95 57 40 101 35c35-4 42 31 74 45 42 19 9 65 17 99 9 40-18 90-59 88-35-2-58 15-90-20Z" fill="url(#tissue)"/>
        <path class="anatomy-pseudopod" d="M61 222Q18 258 38 289M159 223q48 22 28 62M48 116Q12 94 26 61"/><ellipse class="internal-organ" cx="94" cy="137" rx="29" ry="43"/><ellipse class="internal-organ" cx="146" cy="182" rx="19" ry="31"/>
        <circle class="anatomy-eye reactive-organ" cx="85" cy="102" r="7"/><circle class="anatomy-eye reactive-organ" cx="115" cy="110" r="5"/><path class="bio-vein" d="M52 180q58-52 121 16M76 55q19 73 94 85"/><circle class="bio-core" cx="118" cy="166" r="18"/>
      SVG
    end

    def specimen_aberrant(_profile, rng)
      satellites = 4.times.map do |index|
        angle = index * Math::PI / 2 + 0.35
        x = 110 + Math.cos(angle) * (63 + rng.rand(0..16)); y = 151 + Math.sin(angle) * (76 + rng.rand(0..15))
        %(<g class="radial-lobe" style="--part:#{index}"><path class="anatomy-limb" d="M110 151Q#{(110 + x) / 2} #{(151 + y) / 2} #{x.round} #{y.round}"/><ellipse class="anatomy-surface" cx="#{x.round}" cy="#{y.round}" rx="18" ry="27" fill="url(#tissue)"/></g>)
      end.join
      <<~SVG
        #{satellites}<path class="anatomy-surface radial-body" d="m110 53 48 30 22 68-27 69-43 31-49-27-21-73 25-68 45-30Z" fill="url(#tissue)"/>
        <circle class="bio-core" cx="91" cy="136" r="19"/><circle class="bio-core bio-core--secondary" cx="132" cy="174" r="14"/><path class="bio-vein" d="m110 53v198M40 151h140M65 83l88 137"/>
      SVG
    end

    def tracking_nodes(profile, rng)
      (6 + profile.morphology[:segment_count] / 2).times.map do |index|
        x = rng.rand(55..165); y = rng.rand(55..245)
        %(<g class="tracking-node" style="--node:#{index}"><circle cx="#{x}" cy="#{y}" r="3"/><path d="M#{x - 8} #{y}h5m6 0h5M#{x} #{y - 8}v5m0 6v5"/></g>)
      end.join
    end
end
