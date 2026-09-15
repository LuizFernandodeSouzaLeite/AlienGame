require "test_helper"

class SpaceInterfaceTest < ActionDispatch::IntegrationTest
  test "root and nested pages identify the current navigation section" do
    [ root_url, alien_url(aliens(:one)), edit_alien_url(aliens(:one)) ].each do |url|
      get url
      assert_response :success
      assert_select 'nav a[aria-current="page"][href=?]', aliens_path, count: 1
    end
  end

  test "empty archives provide a registration action" do
    Alien.destroy_all
    Planet.destroy_all
    Power.destroy_all

    get aliens_url
    assert_response :success
    assert_select ".archive-file--new[href=?]", new_alien_path
    assert_select ".archive-count", "00 FILES"
    assert_select ".empty-chamber-readout", text: /NO SPECIMEN/

    { planets_url => new_planet_path, powers_url => new_power_path }.each do |url, registration_path|
      get url
      assert_response :success
      assert_select ".empty-state a[href=?]", registration_path
      assert_select ".count-badge", "00"
    end
  end

  test "invalid alien submission preserves selected homeworld and abilities" do
    planet = planets(:two)
    power = powers(:two)
    assert_no_difference("Alien.count") do
      post aliens_url, params: { alien: { name: "", age: 120, planet_id: planet.id, power_ids: [ power.id ] } }
    end
    assert_response :unprocessable_content
    assert_select '[role="alert"]', text: /Name can't be blank/
    assert_select 'input[name="alien[name]"][aria-invalid="true"]'
    assert_select 'select[name="alien[planet_id]"] option[selected][value=?]', planet.id.to_s
    assert_select 'input[name="alien[power_ids][]"][checked][value=?]', power.id.to_s
  end

  test "planet deletion confirmation explains the existing cascading deletion" do
    get planet_url(planets(:one))
    assert_select "form[data-turbo-confirm]", count: 1 do |forms|
      assert_includes forms.first["data-turbo-confirm"], "Aliens on this planet will also be deleted."
    end
  end

  test "record names are escaped in files and confirmation messages" do
    alien = aliens(:one)
    alien.update!(name: '<script>alert("x")</script>')
    get alien_url(alien)
    assert_response :success
    assert_select ".monitor-screen h1", text: alien.name
    assert_select ".monitor-screen h1 script", count: 0
    assert_select "form[data-turbo-confirm]", count: 1
  end

  test "archive exposes large collections and long persisted names" do
    planet = planets(:one)
    20.times { |index| Alien.create!(name: "Specimen #{index} with a deliberately long archive designation", age: index, planet: planet) }

    get aliens_url
    assert_response :success
    assert_select ".archive-file:not(.archive-file--new)", count: 22
    assert_select ".archive-count", "22 FILES"
  end

  test "archive remains usable with one and three specimens" do
    planet = planets(:one)
    Alien.destroy_all

    Alien.create!(name: "Solo specimen", age: 14, planet: planet)
    get aliens_url
    assert_response :success
    assert_select ".archive-file:not(.archive-file--new)", count: 1
    assert_select ".archive-count", "01 FILES"

    2.times { |index| Alien.create!(name: "Additional specimen #{index}", age: 20 + index, planet: planet) }
    get aliens_url
    assert_response :success
    assert_select ".archive-file:not(.archive-file--new)", count: 3
    assert_select ".archive-count", "03 FILES"
  end
end
