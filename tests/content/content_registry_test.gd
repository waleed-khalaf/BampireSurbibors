extends GdUnitTestSuite
## The content registry loads content data from Resource files and rejects
## broken content with a message a designer can act on.

const NOT_SHIREEN_PATH: String = "res://tests/content/fixtures/not_shireen.tres"
const MISSING_PATH: String = "res://tests/content/fixtures/does_not_exist.tres"
const UNREADABLE_PATH: String = "res://tests/content/fixtures/unreadable.tres"


func test_the_real_content_passes_validation() -> void:
	var content := ContentRegistry.load_default()

	assert_array(content.errors).is_empty()
	assert_bool(content.is_valid()).is_true()


func test_the_real_content_gives_shireen_90_pixels_per_second() -> void:
	# The design doc's starting value (design §4).
	assert_float(ContentRegistry.load_default().shireen.move_speed).is_equal(90.0)


func test_a_shireen_who_cannot_move_is_rejected() -> void:
	var content := ContentRegistry.from_data(TestContent.shireen_with_speed(0.0))

	assert_bool(content.is_valid()).is_false()
	assert_array(content.errors).contains_exactly([
		"Shireen: move_speed must be between 10 and 400 px/s, but it is 0.",
	])


func test_an_absurdly_fast_shireen_is_rejected() -> void:
	var content := ContentRegistry.from_data(TestContent.shireen_with_speed(5000.0))

	assert_array(content.errors).contains_exactly([
		"Shireen: move_speed must be between 10 and 400 px/s, but it is 5000.",
	])


func test_the_real_content_gives_shireen_100_patience() -> void:
	# The design doc's starting value (design §4).
	assert_float(ContentRegistry.load_default().shireen.max_patience).is_equal(100.0)


func test_a_shireen_with_no_patience_is_rejected() -> void:
	var content := ContentRegistry.from_data(TestContent.shireen_with_patience(0.0))

	assert_array(content.errors).contains_exactly([
		"Shireen: max_patience must be between 1 and 10000, but it is 0.",
	])


func test_a_missing_data_file_is_rejected_with_its_path() -> void:
	var content := ContentRegistry.load_from(MISSING_PATH)

	assert_bool(content.is_valid()).is_false()
	assert_array(content.errors).contains_exactly([
		"Shireen: no data file at %s." % MISSING_PATH,
	])


func test_a_data_file_of_the_wrong_type_is_rejected() -> void:
	var content := ContentRegistry.load_from(NOT_SHIREEN_PATH)

	assert_array(content.errors).contains_exactly([
		"Shireen: %s is a Gradient, not ShireenData. Its script should be res://src/content/shireen_data.gd." % NOT_SHIREEN_PATH,
	])


## A hand-edit typo leaves a file Godot can't parse. That must be a message,
## not a crash.
func test_a_data_file_godot_cannot_read_is_rejected() -> void:
	var content := ContentRegistry.load_from(UNREADABLE_PATH)

	assert_array(content.errors).contains_exactly([
		"Shireen: %s could not be read. Open it in Godot to see what is wrong with it." % UNREADABLE_PATH,
	])


# --- Admirers ---------------------------------------------------------------

func _uncle() -> AdmirerData:
	var uncle := AdmirerData.new()
	uncle.id = &"dowry_uncle"
	return uncle


func _content_with(admirers: Array[AdmirerData], spawns: SpawnRampData = null) -> ContentRegistry:
	return ContentRegistry.from_data(TestContent.shireen_with_speed(90.0), admirers, spawns)


func test_the_real_dowry_uncle_has_the_design_numbers() -> void:
	# Design §7: HP 30, speed 40, drain 10/s, cash 2, walks straight at you.
	var uncle: AdmirerData = ContentRegistry.load_default().admirers[&"dowry_uncle"]

	assert_float(uncle.max_hp).is_equal(30.0)
	assert_float(uncle.move_speed).is_equal(40.0)
	assert_float(uncle.drain_per_second).is_equal(10.0)
	assert_int(uncle.cash).is_equal(2)
	assert_str(uncle.behavior_id).is_equal("chase")


func test_a_behavior_is_chosen_by_its_id() -> void:
	var content := ContentRegistry.load_default()

	var behavior: AdmirerBehavior = content.create_admirer_behavior(content.admirers[&"dowry_uncle"])

	assert_bool(behavior is ChaseBehavior).is_true()


func test_the_real_spawn_ramp_brings_dowry_uncles() -> void:
	assert_str(ContentRegistry.load_default().spawn_ramp.admirer_id).is_equal("dowry_uncle")


func test_an_unknown_behavior_id_is_rejected() -> void:
	var uncle := _uncle()
	uncle.behavior_id = &"moonwalk"

	assert_array(_content_with([uncle]).errors).contains_exactly([
		"Admirer dowry_uncle: behavior_id \"moonwalk\" is not a known behavior. Known behaviors: chase.",
	])


func test_a_spawn_ramp_for_an_unknown_admirer_is_rejected() -> void:
	var spawns := TestContent.steady_spawns(&"dowry_aunt", 1.0, 10)

	assert_array(_content_with([_uncle()], spawns).errors).contains_exactly([
		"Spawn ramp: admirer_id \"dowry_aunt\" is not an admirer type. Known types: dowry_uncle.",
	])


func test_an_admirer_who_cannot_move_is_rejected() -> void:
	var uncle := _uncle()
	uncle.move_speed = 0.0

	assert_array(_content_with([uncle]).errors).contains_exactly([
		"Admirer dowry_uncle: move_speed must be between 10 and 400 px/s, but it is 0.",
	])


func test_two_admirer_types_with_the_same_id_are_rejected() -> void:
	assert_array(_content_with([_uncle(), _uncle()]).errors).contains_exactly([
		"Admirer dowry_uncle: the id is used by more than one admirer type. Each needs its own.",
	])


func test_a_missing_admirer_folder_is_rejected() -> void:
	var content := ContentRegistry.load_from(ContentRegistry.SHIREEN_PATH, "res://tests/content/fixtures/no_admirers_here", ContentRegistry.SPAWN_RAMP_PATH)

	# The spawn ramp then also names an admirer that doesn't exist.
	assert_array(content.errors).contains_exactly([
		"Admirers: no admirer data files in res://tests/content/fixtures/no_admirers_here.",
		"Spawn ramp: admirer_id \"dowry_uncle\" is not an admirer type. Known types: (none).",
	])


# --- Weapons ----------------------------------------------------------------

func test_the_real_zills_have_the_design_numbers() -> void:
	# Design §6.1: throws 1 zill every 1.2 s, damage 10, pierce 0.
	var zills: WeaponData = ContentRegistry.load_default().weapons[&"zills"]

	assert_str(zills.behavior_id).is_equal("zills")
	assert_float(zills.base_stats[&"count"]).is_equal(1.0)
	assert_float(zills.base_stats[&"cooldown"]).is_equal(1.2)
	assert_float(zills.base_stats[&"damage"]).is_equal(10.0)
	assert_float(zills.base_stats[&"pierce"]).is_equal(0.0)


func test_the_real_zills_have_the_four_buff_tracks_of_the_design() -> void:
	# Design §6.1: Damage, Throw rate, Count, Speed and pierce.
	var zills: WeaponData = ContentRegistry.load_default().weapons[&"zills"]
	var names: Array[String] = []
	for track: BuffTrackData in zills.buff_tracks:
		names.append(track.display_name)
		assert_int(track.max_rank).is_equal(5)

	assert_array(names).is_equal(["Damage", "Throw rate", "Count", "Speed and pierce"])


func test_a_weapon_behavior_is_chosen_by_its_id() -> void:
	var content := ContentRegistry.load_default()

	var behavior: WeaponBehavior = content.create_weapon_behavior(content.weapons[&"zills"])

	assert_bool(behavior is ZillsBehavior).is_true()


func _content_with_weapon(weapon: WeaponData) -> ContentRegistry:
	return ContentRegistry.from_data(TestContent.shireen_with_speed(90.0), [], null, [weapon])


func test_a_copy_of_the_real_zills_passes_validation() -> void:
	assert_array(_content_with_weapon(TestContent.zills_with({})).errors).is_empty()


func test_an_unknown_weapon_behavior_id_is_rejected() -> void:
	var zills := TestContent.zills_with({})
	zills.behavior_id = &"castanets"

	assert_array(_content_with_weapon(zills).errors).contains_exactly([
		"Weapon zills: behavior_id \"castanets\" is not a known behavior. Known behaviors: zills.",
	])


func test_a_weapon_missing_a_stat_its_behavior_needs_is_rejected() -> void:
	var zills := TestContent.zills_with({})
	zills.base_stats.erase(&"range")

	assert_array(_content_with_weapon(zills).errors).contains_exactly([
		"Weapon zills: base_stats has no \"range\". Its behavior needs: area, cooldown, count, damage, pierce, range, rate, speed.",
	])


func test_a_weapon_that_never_attacks_is_rejected() -> void:
	var zills := TestContent.zills_with({&"cooldown": 0.0})

	assert_array(_content_with_weapon(zills).errors).contains_exactly([
		"Weapon zills: cooldown must be between 0.05 and 60, but it is 0.",
	])


func test_a_weapon_without_exactly_four_buff_tracks_is_rejected() -> void:
	var zills := TestContent.zills_with({})
	zills.buff_tracks.pop_back()

	assert_array(_content_with_weapon(zills).errors).contains_exactly([
		"Weapon zills: it has 3 buff tracks, but a weapon needs exactly 4.",
	])


func test_a_buff_that_changes_a_stat_the_weapon_does_not_have_is_rejected() -> void:
	var zills := TestContent.zills_with({})
	zills.buff_tracks[0].modifiers[0].stat = &"dammage"

	assert_array(_content_with_weapon(zills).errors).contains_exactly([
		"Weapon zills, buff track damage: a modifier changes \"dammage\", which is not one of the weapon's stats (area, cooldown, count, damage, pierce, range, rate, speed).",
	])


func test_a_buff_granted_at_a_rank_the_track_does_not_have_is_rejected() -> void:
	var zills := TestContent.zills_with({})
	# The Count track: +1 zill at ranks 1, 3 and... 7.
	zills.buff_tracks[2].modifiers[0].ranks = PackedInt32Array([1, 3, 7])

	assert_array(_content_with_weapon(zills).errors).contains_exactly([
		"Weapon zills, buff track count: a modifier is granted at rank 7, but the track only has ranks 1 to 5.",
	])


func test_two_buff_tracks_with_the_same_id_are_rejected() -> void:
	var zills := TestContent.zills_with({})
	zills.buff_tracks[1].id = &"damage"

	assert_array(_content_with_weapon(zills).errors).contains_exactly([
		"Weapon zills, buff track damage: the id is used by more than one of the weapon's buff tracks. Each needs its own.",
	])


func test_an_ability_with_an_unknown_behavior_id_is_rejected() -> void:
	var zills := TestContent.zills_with({})
	var ability := AbilityData.new()
	ability.id = &"ricochet"
	ability.behavior_id = &"bounce"
	zills.abilities.append(ability)

	assert_array(_content_with_weapon(zills).errors).contains_exactly([
		"Weapon zills, ability ricochet: behavior_id \"bounce\" is not a known ability behavior. Known behaviors: (none).",
	])


func test_an_ability_modifier_that_lists_ranks_is_rejected() -> void:
	var zills := TestContent.zills_with({})
	var modifier := StatModifierData.new()
	modifier.stat = &"damage"
	modifier.ranks = PackedInt32Array([3])
	var ability := AbilityData.new()
	ability.id = &"ricochet"
	ability.modifiers.append(modifier)
	zills.abilities.append(ability)

	assert_array(_content_with_weapon(zills).errors).contains([
		"Weapon zills, ability ricochet: a modifier lists ranks, but only buff tracks have ranks. Clear its ranks.",
	])


func test_a_buff_track_with_more_than_five_ranks_is_rejected() -> void:
	var zills := TestContent.zills_with({})
	zills.buff_tracks[0].max_rank = 6

	assert_array(_content_with_weapon(zills).errors).contains_exactly([
		"Weapon zills, buff track damage: max_rank must be between 1 and 5, but it is 6.",
	])


func test_a_weapon_with_an_empty_buff_track_slot_is_rejected() -> void:
	var zills := TestContent.zills_with({})
	# What adding a slot in the Inspector and not filling it leaves behind.
	zills.buff_tracks[3] = null

	assert_array(_content_with_weapon(zills).errors).contains_exactly([
		"Weapon zills: buff track slot 4 is empty. Fill it, or remove the slot.",
	])


func test_a_buff_track_with_an_empty_modifier_slot_is_rejected() -> void:
	var zills := TestContent.zills_with({})
	zills.buff_tracks[0].modifiers.append(null)

	assert_array(_content_with_weapon(zills).errors).contains_exactly([
		"Weapon zills, buff track damage: modifier slot 2 is empty. Fill it, or remove the slot.",
	])


func test_a_weapon_with_an_empty_ability_slot_is_rejected() -> void:
	var zills := TestContent.zills_with({})
	zills.abilities.append(null)

	assert_array(_content_with_weapon(zills).errors).contains_exactly([
		"Weapon zills: ability slot 1 is empty. Fill it, or remove the slot.",
	])


func test_a_buff_that_takes_a_stat_below_its_range_is_rejected() -> void:
	var zills := TestContent.zills_with({})
	# The Count track: one zill fewer at ranks 1, 3 and 5, instead of one more.
	zills.buff_tracks[2].modifiers[0].value = -1.0

	assert_array(_content_with_weapon(zills).errors).contains_exactly([
		"Weapon zills: its buffs and abilities can take count as low as -2, but it must stay between 1 and 20.",
	])


func test_buffs_that_remove_the_whole_cooldown_are_rejected() -> void:
	var zills := TestContent.zills_with({})
	# The Throw Rate track: -20% cooldown a rank, so no cooldown at rank 5.
	zills.buff_tracks[1].modifiers[0].stat = &"cooldown"
	zills.buff_tracks[1].modifiers[0].value = -0.2

	assert_array(_content_with_weapon(zills).errors).contains_exactly([
		"Weapon zills: its buffs and abilities can take cooldown as low as 0, but it must stay between 0.05 and 60.",
	])


func test_a_buff_that_takes_a_stat_above_its_range_is_rejected() -> void:
	var zills := TestContent.zills_with({})
	# The Speed & Pierce track: +100% zill speed a rank instead of +10%.
	zills.buff_tracks[3].modifiers[0].value = 1.0

	assert_array(_content_with_weapon(zills).errors).contains_exactly([
		"Weapon zills: its buffs and abilities can take speed as high as 1320, but it must stay between 20 and 600.",
	])


func test_two_weapons_with_the_same_id_are_rejected() -> void:
	var content := ContentRegistry.from_data(TestContent.shireen_with_speed(90.0), [], null, [TestContent.zills_with({}), TestContent.zills_with({})])

	assert_array(content.errors).contains_exactly([
		"Weapon zills: the id is used by more than one weapon. Each needs its own.",
	])


func test_a_missing_weapon_folder_is_rejected() -> void:
	var content := ContentRegistry.load_from(ContentRegistry.SHIREEN_PATH, ContentRegistry.ADMIRERS_DIR, ContentRegistry.SPAWN_RAMP_PATH, "res://tests/content/fixtures/no_weapons_here")

	assert_array(content.errors).contains_exactly([
		"Weapons: no weapon data files in res://tests/content/fixtures/no_weapons_here.",
	])


func test_an_admirer_who_swoons_forever_is_rejected() -> void:
	var uncle := _uncle()
	uncle.swoon_seconds = 60.0

	assert_array(_content_with([uncle]).errors).contains_exactly([
		"Admirer dowry_uncle: swoon_seconds must be between 0 and 5 s, but it is 60.",
	])
