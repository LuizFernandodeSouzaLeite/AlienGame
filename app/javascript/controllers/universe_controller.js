import { Controller } from "@hotwired/stimulus"
import * as THREE from "three"

// A persistent WebGL scene the whole app floats inside of. The element is
// data-turbo-permanent, so Turbo keeps this exact <canvas> node alive across
// visits — we build the Three.js engine once and stash it on the element
// itself, then just pause/resume the render loop as Stimulus connects and
// disconnects around navigations. Rebuilding the renderer on every visit
// (the previous approach) raced WebGL context teardown against the next
// connect() and left the canvas blank after the first navigation.
const SECTIONS = {
  aliens: { hue: 174, accent: 0x76eadc, energetic: false },
  planets: { hue: 262, accent: 0xbdacff, energetic: false },
  powers: { hue: 213, accent: 0x8ab9ff, energetic: true },
}
const DEFAULT_SECTION = "aliens"

export default class extends Controller {
  static targets = ["canvas"]

  connect() {
    this.motion = window.matchMedia("(prefers-reduced-motion: reduce)")
    this.mobile = window.innerWidth <= 720
    this.canvas = document.querySelector("#universe-engine canvas")
    if (!this.canvas) return

    // Turbo keeps the canvas node. Store the renderer there so a fresh body
    // controller can reconnect without inheriting a stale Stimulus scope.
    this.engine = this.canvas.__universeEngine ||= this.buildEngine()
    if (!this.engine) return

    this.bindEvents()
    this.onResize()
    this.renderFrame(true)
    if (!this.motion.matches && !document.hidden) this.start()
    this.mask()
  }

  disconnect() {
    // The canvas and its WebGL context are reused on the next connect() —
    // only stop the loop and drop this instance's own listeners.
    this.stop()
    this.abort?.abort()
  }

  mask(event) {
    if (!this.canvas) return
    if (document.body.dataset.section !== "aliens" || !event?.detail) return
    const { width, height } = event.detail
    this.engine.renderer.setSize(width, height, false)
    this.engine.camera.aspect = width / height
    this.engine.camera.updateProjectionMatrix()
    this.renderFrame(true)
  }

  // ---------- one-time engine construction ----------

  buildEngine() {
    let renderer
    try {
      renderer = new THREE.WebGLRenderer({
        canvas: this.canvas,
        alpha: true,
        antialias: !this.mobile,
        powerPreference: "high-performance",
      })
    } catch {
      return null
    }
    renderer.setClearColor(0x000000, 0)
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, this.mobile ? 1.25 : 1.75))

    const mobile = this.mobile
    const scene = new THREE.Scene()
    const camera = new THREE.PerspectiveCamera(48, 1, 0.1, 120)
    camera.position.set(0, 0, 32)

    scene.add(new THREE.AmbientLight(0x2a3550, 1.1))
    const keyLight = new THREE.DirectionalLight(0xbcd8ff, 2.1)
    keyLight.position.set(-14, 8, 12)
    scene.add(keyLight)

    const starSprite = this.makeStarTexture()
    const buildStars = ({ count, radius, size, opacity }) => {
      const positions = new Float32Array(count * 3)
      for (let i = 0; i < count; i++) {
        const r = radius * (0.4 + Math.random() * 0.6)
        const theta = Math.random() * Math.PI * 2
        const phi = Math.acos(Math.random() * 2 - 1)
        positions[i * 3] = r * Math.sin(phi) * Math.cos(theta)
        positions[i * 3 + 1] = r * Math.sin(phi) * Math.sin(theta) * 0.6
        positions[i * 3 + 2] = r * Math.cos(phi) - 10
      }
      const geometry = new THREE.BufferGeometry()
      geometry.setAttribute("position", new THREE.BufferAttribute(positions, 3))
      const material = new THREE.PointsMaterial({
        size, color: 0xdbe8ff, map: starSprite, transparent: true, opacity, depthWrite: false, sizeAttenuation: true,
      })
      return new THREE.Points(geometry, material)
    }

    const starLayers = [
      buildStars({ count: mobile ? 220 : 620, radius: 60, size: 0.32, opacity: 0.55 }),
      buildStars({ count: mobile ? 140 : 420, radius: 42, size: 0.5, opacity: 0.75 }),
      buildStars({ count: mobile ? 70 : 220, radius: 26, size: 0.75, opacity: 0.9 }),
    ]
    starLayers.forEach((layer, i) => {
      layer.userData.spin = 0.002 + i * 0.0015
      scene.add(layer)
    })

    const dust = mobile ? null : buildStars({ count: 90, radius: 16, size: 0.22, opacity: 0.35 })
    if (dust) {
      dust.userData.spin = 0.01
      scene.add(dust)
    }

    const distantSun = new THREE.Sprite(new THREE.SpriteMaterial({
      map: starSprite, color: 0xffddb0, transparent: true, opacity: 0.42,
      depthWrite: false, blending: THREE.AdditiveBlending,
    }))
    distantSun.position.set(-12, 8, -34)
    distantSun.scale.set(3.4, 3.4, 1)
    scene.add(distantSun)

    const asteroidGroup = new THREE.Group()
    asteroidGroup.visible = false
    for (let index = 0; index < 5; index++) {
      const asteroid = new THREE.Mesh(
        new THREE.IcosahedronGeometry(0.18 + index * 0.045, 0),
        new THREE.MeshStandardMaterial({ color: 0x687077, roughness: 1 })
      )
      asteroid.position.set(index * 1.15, Math.sin(index * 2.1) * 0.7, Math.cos(index) * 0.8)
      asteroid.rotation.set(index, index * 0.7, 0)
      asteroidGroup.add(asteroid)
    }
    asteroidGroup.position.set(17, -5, -16)
    scene.add(asteroidGroup)

    const currentSection = document.body.dataset.section || DEFAULT_SECTION
    const nebulae = mobile ? [] : [-16, 18].map((x, i) => {
      const sprite = new THREE.Sprite(new THREE.SpriteMaterial({
        map: this.makeNebulaTexture(SECTIONS[currentSection].hue),
        transparent: true, opacity: 0.16, depthWrite: false, blending: THREE.AdditiveBlending,
      }))
      const scale = i === 0 ? 34 : 30
      sprite.position.set(x, i === 0 ? 6 : -10, -30 - i * 4)
      sprite.scale.set(scale, scale, 1)
      sprite.userData.baseScale = scale
      scene.add(sprite)
      return sprite
    })

    const planetTextures = {
      aliens: this.makePlanetTexture(SECTIONS.aliens),
      planets: this.makePlanetTexture(SECTIONS.planets),
      powers: this.makePlanetTexture(SECTIONS.powers),
    }

    const planetGroup = new THREE.Group()
    planetGroup.position.set(mobile ? 9 : 13, mobile ? -3 : 1.5, -6)
    scene.add(planetGroup)

    const radius = mobile ? 4.4 : 8.6
    const planetMesh = new THREE.Mesh(
      new THREE.SphereGeometry(radius, 48, 48),
      new THREE.MeshStandardMaterial({ map: planetTextures[currentSection], roughness: 0.9, metalness: 0.05 })
    )
    planetMesh.rotation.z = 0.36
    planetGroup.add(planetMesh)

    const atmosphere = new THREE.Mesh(
      new THREE.SphereGeometry(radius * 1.12, 48, 48),
      new THREE.ShaderMaterial({
        uniforms: { glowColor: { value: new THREE.Color(SECTIONS[currentSection].accent) } },
        vertexShader: `varying vec3 vNormal; void main() { vNormal = normalize(normalMatrix * normal); gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }`,
        fragmentShader: `uniform vec3 glowColor; varying vec3 vNormal; void main() { float intensity = pow(0.62 - dot(vNormal, vec3(0.0, 0.0, 1.0)), 3.0); gl_FragColor = vec4(glowColor, intensity); }`,
        side: THREE.BackSide,
        blending: THREE.AdditiveBlending,
        transparent: true,
        depthWrite: false,
      })
    )
    planetGroup.add(atmosphere)

    let moonPivot = null
    if (!mobile) {
      moonPivot = new THREE.Group()
      moonPivot.rotation.x = 0.5
      planetGroup.add(moonPivot)
      const moon = new THREE.Mesh(
        new THREE.SphereGeometry(radius * 0.16, 20, 20),
        new THREE.MeshStandardMaterial({ color: 0x8892a0, roughness: 1 })
      )
      moon.position.set(radius * 1.9, 0, 0)
      moonPivot.add(moon)
    }

    return {
      mobile, renderer, scene, camera, keyLight, starLayers, dust, distantSun, asteroidGroup, nebulae,
      planetTextures, planetGroup, planetMesh, atmosphere, moonPivot,
      clock: new THREE.Clock(), currentSection, colorMix: 1, fromColors: null, toColors: null,
      pointer: { x: 0, y: 0 }, smoothed: { x: 0, y: 0 }, kick: 0, meteor: null, nextMeteor: undefined,
      asteroidPass: null, nextAsteroidPass: undefined,
    }
  }

  makeStarTexture() {
    const size = 64
    const canvas = document.createElement("canvas")
    canvas.width = canvas.height = size
    const ctx = canvas.getContext("2d")
    const g = ctx.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size / 2)
    g.addColorStop(0, "rgba(255,255,255,1)")
    g.addColorStop(0.4, "rgba(255,255,255,.85)")
    g.addColorStop(1, "rgba(255,255,255,0)")
    ctx.fillStyle = g
    ctx.fillRect(0, 0, size, size)
    return new THREE.CanvasTexture(canvas)
  }

  makeNebulaTexture(hue) {
    const size = 512
    const canvas = document.createElement("canvas")
    canvas.width = canvas.height = size
    const ctx = canvas.getContext("2d")
    const g = ctx.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size / 2)
    g.addColorStop(0, `hsla(${hue}, 70%, 62%, .55)`)
    g.addColorStop(0.5, `hsla(${hue}, 70%, 45%, .16)`)
    g.addColorStop(1, `hsla(${hue}, 70%, 30%, 0)`)
    ctx.fillStyle = g
    ctx.fillRect(0, 0, size, size)
    return new THREE.CanvasTexture(canvas)
  }

  makePlanetTexture({ hue, energetic }) {
    const w = 512, h = 256
    const canvas = document.createElement("canvas")
    canvas.width = w; canvas.height = h
    const ctx = canvas.getContext("2d")
    ctx.fillStyle = `hsl(${hue}, 38%, 13%)`
    ctx.fillRect(0, 0, w, h)
    const bands = 16
    for (let i = 0; i < bands; i++) {
      const y = (i / bands) * h
      const bandH = h / bands + 1
      const light = 16 + Math.sin(i * 1.4) * 9 + (i % 3) * 4
      ctx.fillStyle = `hsla(${hue + (i % 2 ? 8 : -8)}, 45%, ${light}%, ${0.55 + Math.random() * 0.25})`
      ctx.fillRect(0, y, w, bandH)
    }
    ctx.globalAlpha = 0.16
    for (let i = 0; i < 50; i++) {
      ctx.fillStyle = i % 2 ? "#ffffff" : "#000000"
      ctx.fillRect(0, Math.random() * h, w, Math.random() * 2 + 0.4)
    }
    ctx.globalAlpha = 1
    if (energetic) {
      ctx.strokeStyle = `hsla(${hue}, 90%, 78%, .75)`
      ctx.lineWidth = 1.4
      for (let i = 0; i < 5; i++) {
        const y = Math.random() * h
        ctx.beginPath()
        ctx.moveTo(0, y)
        ctx.bezierCurveTo(w * 0.3, y + (Math.random() - 0.5) * 46, w * 0.6, y + (Math.random() - 0.5) * 46, w, y)
        ctx.stroke()
      }
    }
    const texture = new THREE.CanvasTexture(canvas)
    texture.wrapS = THREE.RepeatWrapping
    return texture
  }

  // ---------- lifecycle wiring (rebound on every connect) ----------

  bindEvents() {
    this.abort = new AbortController()
    const opts = { signal: this.abort.signal }
    window.addEventListener("resize", () => this.onResize(), opts)
    window.addEventListener("pointermove", (e) => {
      if (this.motion.matches || this.mobile || e.pointerType !== "mouse") return
      this.engine.pointer.x = e.clientX / window.innerWidth - 0.5
      this.engine.pointer.y = e.clientY / window.innerHeight - 0.5
    }, { ...opts, passive: true })
    document.addEventListener("visibilitychange", () => {
      document.hidden ? this.stop() : (!this.motion.matches && this.start())
    }, opts)
    document.addEventListener("turbo:before-visit", () => this.travel(), opts)
    document.addEventListener("turbo:load", () => this.onNavigate(), opts)
    this.motion.addEventListener("change", () => (this.motion.matches ? this.stop() : this.start()), opts)
  }

  onResize() {
    const width = window.innerWidth
    const height = window.innerHeight
    this.mobile = width <= 720
    this.engine.renderer.setSize(width, height, false)
    this.engine.camera.aspect = width / height
    this.engine.camera.updateProjectionMatrix()
    this.renderFrame(true)
  }

  onNavigate() {
    const section = document.body.dataset.section
    if (section && section !== this.engine.currentSection && SECTIONS[section]) {
      this.applySection(section, this.motion.matches)
      if (this.motion.matches) this.renderFrame(true)
    }
  }

  applySection(name, instant) {
    const e = this.engine
    const config = SECTIONS[name] || SECTIONS[DEFAULT_SECTION]
    e.currentSection = name
    e.fromColors = { accent: e.keyLight.color.clone(), glow: e.atmosphere.material.uniforms.glowColor.value.clone() }
    e.toColors = { accent: new THREE.Color(config.accent), glow: new THREE.Color(config.accent) }
    e.colorMix = instant ? 1 : 0
    e.planetMesh.material.map = e.planetTextures[name]
    e.planetMesh.material.needsUpdate = true
    e.nebulae.forEach((n) => (n.material.map = this.makeNebulaTexture(config.hue)))
    if (instant) {
      e.keyLight.color.copy(e.toColors.accent)
      e.atmosphere.material.uniforms.glowColor.value.copy(e.toColors.glow)
    }
  }

  travel() {
    if (this.motion.matches) return
    this.engine.kick = 1
  }

  // ---------- render loop ----------

  start() {
    if (this.frame || this.motion.matches) return
    this.frame = requestAnimationFrame(() => this.loop())
  }

  stop() {
    cancelAnimationFrame(this.frame)
    this.frame = null
  }

  loop() {
    this.renderFrame(false)
    this.frame = requestAnimationFrame(() => this.loop())
  }

  renderFrame(still) {
    const e = this.engine
    const dt = still ? 0 : Math.min(e.clock.getDelta(), 0.1)
    const t = e.clock.elapsedTime

    e.smoothed.x += (e.pointer.x - e.smoothed.x) * 0.05
    e.smoothed.y += (e.pointer.y - e.smoothed.y) * 0.05
    e.kick *= 0.9

    const driftX = Math.sin(t * 0.05) * 1.1 + Math.sin(t * 0.021) * 0.6
    const driftY = Math.cos(t * 0.04) * 0.7
    e.camera.position.x = driftX + e.smoothed.x * 3.2 + e.kick * Math.sin(t * 30) * 0.4
    e.camera.position.y = driftY - e.smoothed.y * 2.2
    e.camera.fov = 48 + e.kick * 3
    e.camera.updateProjectionMatrix()
    e.camera.lookAt(2, 0, -4)

    if (!still) {
      e.starLayers.forEach((layer) => { layer.rotation.y += dt * layer.userData.spin })
      if (e.dust) e.dust.rotation.y -= dt * e.dust.userData.spin
      e.nebulae.forEach((n, i) => {
        n.material.rotation += dt * (i === 0 ? 0.01 : -0.007)
        n.scale.setScalar(n.userData.baseScale * (1 + Math.sin(t * 0.03 + i) * 0.04))
      })
      e.planetMesh.rotation.y += dt * 0.045
      if (e.moonPivot) e.moonPivot.rotation.y += dt * 0.12
      this.updateMeteor(t)
      this.updateAsteroidPass(t, dt)
    }

    if (e.colorMix < 1) {
      e.colorMix = Math.min(1, e.colorMix + dt * 0.8)
      e.keyLight.color.copy(e.fromColors.accent).lerp(e.toColors.accent, e.colorMix)
      e.atmosphere.material.uniforms.glowColor.value.copy(e.fromColors.glow).lerp(e.toColors.glow, e.colorMix)
    }

    e.renderer.render(e.scene, e.camera)
  }

  // ---------- occasional shooting star ----------

  updateMeteor(t) {
    const e = this.engine
    if (e.mobile) return
    if (e.nextMeteor === undefined) e.nextMeteor = t + 8 + Math.random() * 15
    if (t > e.nextMeteor && !e.meteor) {
      const start = new THREE.Vector3((Math.random() - 0.5) * 30, 10 + Math.random() * 6, -20 - Math.random() * 10)
      const geometry = new THREE.BufferGeometry().setFromPoints([start, start.clone()])
      const material = new THREE.LineBasicMaterial({ color: 0xdcefff, transparent: true, opacity: 0 })
      e.meteor = new THREE.Line(geometry, material)
      e.meteor.userData = { start, born: t }
      e.scene.add(e.meteor)
    }
    if (e.meteor) {
      const age = t - e.meteor.userData.born
      if (age > 1.1) {
        e.scene.remove(e.meteor)
        e.meteor.geometry.dispose()
        e.meteor.material.dispose()
        e.meteor = null
        e.nextMeteor = t + 8 + Math.random() * 15
        return
      }
      const { start } = e.meteor.userData
      const end = start.clone().add(new THREE.Vector3(-9, -5, 0).multiplyScalar(Math.min(age * 1.6, 1)))
      const tail = start.clone().add(new THREE.Vector3(-9, -5, 0).multiplyScalar(Math.max(age * 1.6 - 0.25, 0)))
      e.meteor.geometry.setFromPoints([tail, end])
      e.meteor.material.opacity = Math.sin(Math.min(age / 1.1, 1) * Math.PI) * 0.85
    }
  }

  
  // A small, infrequent belt crossing keeps the exterior alive without turning
  // the observation port into a constant effects reel.
  updateAsteroidPass(t, dt) {
    const e = this.engine
    if (e.mobile) return
    if (e.nextAsteroidPass === undefined) e.nextAsteroidPass = t + 18 + Math.random() * 24
    if (t > e.nextAsteroidPass && !e.asteroidPass) {
      e.asteroidPass = { born: t }
      e.asteroidGroup.position.set(17, -5 + Math.random() * 7, -16)
      e.asteroidGroup.visible = true
    }
    if (!e.asteroidPass) return

    e.asteroidGroup.position.x -= dt * 5.2
    e.asteroidGroup.rotation.y += dt * 0.42
    e.asteroidGroup.children.forEach((asteroid, index) => {
      asteroid.rotation.x += dt * (0.25 + index * 0.04)
      asteroid.rotation.z -= dt * 0.18
    })
    if (t - e.asteroidPass.born > 6.5) {
      e.asteroidGroup.visible = false
      e.asteroidPass = null
      e.nextAsteroidPass = t + 28 + Math.random() * 36
    }
  }
}
