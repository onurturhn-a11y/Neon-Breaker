extends Node2D


@onready var left_mount = $LeftWeaponMount
@onready var right_mount = $RightWeaponMount
@onready var main_gun = $MainWeaponMount/MainGun
@onready var left_mount_plate = $LeftWeaponMount/MountPlate
@onready var right_mount_plate = $RightWeaponMount/MountPlate
@onready var left_gun = $LeftWeaponMount/LeftGun
@onready var right_gun = $RightWeaponMount/RightGun
@onready var left_charge = $LeftWeaponMount/LeftGun/LeftMuzzle/ChargeEffect
@onready var right_charge = $RightWeaponMount/RightGun/RightMuzzle/ChargeEffect
@onready var left_fire = $LeftWeaponMount/LeftGun/LeftMuzzle/FireEffect
@onready var right_fire = $RightWeaponMount/RightGun/RightMuzzle/FireEffect
@onready var main_charge = $MainWeaponMount/MainGun/MainMuzzle/ChargeEffect
@onready var main_fire = $MainWeaponMount/MainGun/MainMuzzle/FireEffect
@onready var fire_sound_players = [
	$FireSound1,
	$FireSound2,
	$FireSound3,
	$FireSound4,
	$FireSound5,
	$FireSound6
]

var deployed = false
var next_fire_sound = 0
var combo_chain_rank = -1
var plasma_level = 0
var plasma_evolution: StringName = &"none"
var overcharge_accents: Array[CanvasItem] = []
var ricochet_accents: Array[CanvasItem] = []
var evolution_tween: Tween

const OVERCHARGE_GUN_SCALE := Vector2(1.18, 1.18)
const MAIN_GUN_ROTATION := -PI * 0.5
const LEFT_GUN_ROTATION := PI * 0.5
const RIGHT_GUN_ROTATION := -PI * 0.5
const RICOCHET_SIDE_ROTATION := deg_to_rad(10.0)


func set_plasma_level(level: int, animate_side_upgrade := false) -> void:
	plasma_level = clampi(level, 0, 3)
	var side_enabled: bool = plasma_level >= 2
	left_mount.visible = side_enabled
	right_mount.visible = side_enabled
	if side_enabled and animate_side_upgrade:
		for gun in [left_gun, right_gun]:
			gun.scale = Vector2(0.35, 0.35)
			gun.modulate.a = 0.0
		var reveal := create_tween().set_parallel(true)
		reveal.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		reveal.tween_property(left_gun, "scale", Vector2.ONE, 0.20)
		reveal.tween_property(right_gun, "scale", Vector2.ONE, 0.20)
		reveal.tween_property(left_gun, "modulate:a", 1.0, 0.14)
		reveal.tween_property(right_gun, "modulate:a", 1.0, 0.14)
	update_muzzle_tint()


func set_plasma_evolution(evolution: StringName, animate_transition := false) -> void:
	plasma_evolution = evolution
	var overcharged := plasma_evolution == &"overcharge"
	var ricochet := plasma_evolution == &"ricochet"
	_ensure_overcharge_accents()
	_ensure_ricochet_accents()
	if evolution_tween and evolution_tween.is_valid():
		evolution_tween.kill()

	var target_scale := OVERCHARGE_GUN_SCALE if overcharged else Vector2.ONE
	var target_tint := Color.WHITE
	if overcharged:
		target_tint = Color(1.12, 1.03, 0.78, 1.0)
	elif ricochet:
		target_tint = Color(0.76, 1.08, 1.18, 1.0)
	var left_target_rotation := LEFT_GUN_ROTATION - RICOCHET_SIDE_ROTATION if ricochet else LEFT_GUN_ROTATION
	var right_target_rotation := RIGHT_GUN_ROTATION + RICOCHET_SIDE_ROTATION if ricochet else RIGHT_GUN_ROTATION
	if not animate_transition:
		for gun in [main_gun, left_gun, right_gun]:
			gun.scale = target_scale
			gun.modulate = Color(target_tint.r, target_tint.g, target_tint.b, gun.modulate.a)
		for accent in overcharge_accents:
			accent.modulate.a = 1.0 if overcharged else 0.0
		for accent in ricochet_accents:
			accent.modulate.a = 1.0 if ricochet else 0.0
		main_gun.rotation = MAIN_GUN_ROTATION
		left_gun.rotation = left_target_rotation
		right_gun.rotation = right_target_rotation
		update_muzzle_tint()
		return

	evolution_tween = create_tween().set_parallel(true)
	evolution_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for gun in [main_gun, left_gun, right_gun]:
		evolution_tween.tween_property(gun, "scale", target_scale, 0.32)
		evolution_tween.tween_property(
			gun, "modulate",
			Color(target_tint.r, target_tint.g, target_tint.b, gun.modulate.a), 0.28
		)
	for accent in overcharge_accents:
		accent.modulate.a = 0.0
		evolution_tween.tween_property(accent, "modulate:a", 1.0 if overcharged else 0.0, 0.30)
	for accent in ricochet_accents:
		accent.modulate.a = 0.0
		evolution_tween.tween_property(accent, "modulate:a", 1.0 if ricochet else 0.0, 0.34)
	evolution_tween.tween_property(main_gun, "rotation", MAIN_GUN_ROTATION, 0.34)
	evolution_tween.tween_property(left_gun, "rotation", left_target_rotation, 0.36)
	evolution_tween.tween_property(right_gun, "rotation", right_target_rotation, 0.36)
	update_muzzle_tint()


func _ensure_overcharge_accents() -> void:
	if not overcharge_accents.is_empty():
		return
	for muzzle in [$MainWeaponMount/MainGun/MainMuzzle, left_charge.get_parent(), right_charge.get_parent()]:
		var outer := Polygon2D.new()
		outer.name = "OverchargeOuterGlow"
		outer.polygon = _circle_polygon(9.0, 16)
		outer.color = Color(1.0, 0.32, 0.06, 0.22)
		outer.z_index = -1
		outer.modulate.a = 0.0
		muzzle.add_child(outer)
		overcharge_accents.append(outer)

		var core := Polygon2D.new()
		core.name = "OverchargeEnergyCore"
		core.polygon = _circle_polygon(3.2, 12)
		core.color = Color(0.72, 1.0, 0.34, 0.72)
		core.modulate.a = 0.0
		muzzle.add_child(core)
		overcharge_accents.append(core)


func _circle_polygon(radius: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(point_count):
		points.append(Vector2.from_angle(TAU * float(point_index) / float(point_count)) * radius)
	return points


func _ensure_ricochet_accents() -> void:
	if not ricochet_accents.is_empty():
		return
	for muzzle in [$MainWeaponMount/MainGun/MainMuzzle, left_charge.get_parent(), right_charge.get_parent()]:
		var outer_ring := Line2D.new()
		outer_ring.name = "RicochetOuterCoil"
		outer_ring.points = _circle_polygon(8.0, 20)
		outer_ring.closed = true
		outer_ring.width = 1.35
		outer_ring.default_color = Color(0.3, 0.94, 1.0, 0.78)
		outer_ring.antialiased = true
		outer_ring.modulate.a = 0.0
		muzzle.add_child(outer_ring)
		ricochet_accents.append(outer_ring)

		var inner_ring := Line2D.new()
		inner_ring.name = "RicochetInnerCoil"
		inner_ring.points = _circle_polygon(5.2, 16)
		inner_ring.closed = true
		inner_ring.width = 0.8
		inner_ring.default_color = Color(0.78, 0.98, 1.0, 0.92)
		inner_ring.antialiased = true
		inner_ring.modulate.a = 0.0
		muzzle.add_child(inner_ring)
		ricochet_accents.append(inner_ring)


func show_deployed_immediate():

	deployed = true
	main_gun.position = Vector2(0, -13)
	main_gun.rotation = -PI * 0.5
	main_gun.scale = Vector2.ONE
	main_gun.modulate.a = 1.0

	left_mount_plate.rotation = -0.12
	right_mount_plate.rotation = 0.12

	left_gun.position = Vector2(-7, -13)
	right_gun.position = Vector2(7, -13)
	left_gun.rotation = PI * 0.5
	right_gun.rotation = -PI * 0.5
	left_gun.scale = Vector2.ONE
	right_gun.scale = Vector2.ONE
	left_gun.modulate.a = 1.0
	right_gun.modulate.a = 1.0

	left_charge.modulate.a = 0.0
	right_charge.modulate.a = 0.0
	left_fire.modulate.a = 0.0
	right_fire.modulate.a = 0.0
	main_charge.modulate.a = 0.0
	main_fire.modulate.a = 0.0


func deploy():

	if deployed:
		return

	deployed = true

	var covers = create_tween()
	covers.set_parallel(true)
	covers.tween_property(left_mount_plate, "rotation", -0.12, 0.12)
	covers.tween_property(right_mount_plate, "rotation", 0.12, 0.12)
	await covers.finished

	var extend = create_tween()
	extend.set_parallel(true)
	extend.set_trans(Tween.TRANS_BACK)
	extend.set_ease(Tween.EASE_OUT)
	extend.tween_property(left_gun, "position", Vector2(-7, -13), 0.32)
	extend.tween_property(right_gun, "position", Vector2(7, -13), 0.32)
	extend.tween_property(left_gun, "rotation", PI * 0.5, 0.32)
	extend.tween_property(right_gun, "rotation", -PI * 0.5, 0.32)
	extend.tween_property(left_gun, "scale", Vector2.ONE, 0.32)
	extend.tween_property(right_gun, "scale", Vector2.ONE, 0.32)
	extend.tween_property(left_gun, "modulate:a", 1.0, 0.22)
	extend.tween_property(right_gun, "modulate:a", 1.0, 0.22)
	extend.tween_property(main_gun, "position", Vector2(0, -13), 0.32)
	extend.tween_property(main_gun, "scale", Vector2.ONE, 0.32)
	extend.tween_property(main_gun, "modulate:a", 1.0, 0.22)
	await extend.finished

	var charge = create_tween()
	charge.set_parallel(true)
	charge.tween_property(left_charge, "modulate:a", 1.0, 0.18)
	charge.tween_property(right_charge, "modulate:a", 1.0, 0.18)
	charge.tween_property(left_charge, "scale", Vector2(0.115, 0.115), 0.18)
	charge.tween_property(right_charge, "scale", Vector2(0.115, 0.115), 0.18)
	charge.tween_property(main_charge, "modulate:a", 1.0, 0.18)
	charge.tween_property(main_charge, "scale", Vector2(0.115, 0.115), 0.18)
	await charge.finished

	var lock = create_tween()
	lock.set_parallel(true)
	lock.tween_property(left_gun, "scale", Vector2(1.06, 0.94), 0.04)
	lock.tween_property(right_gun, "scale", Vector2(1.06, 0.94), 0.04)
	lock.tween_property(main_gun, "scale", Vector2(1.06, 0.94), 0.04)
	await lock.finished

	var settle = create_tween()
	settle.set_parallel(true)
	settle.tween_property(left_gun, "scale", Vector2.ONE, 0.04)
	settle.tween_property(right_gun, "scale", Vector2.ONE, 0.04)
	settle.tween_property(left_charge, "modulate:a", 0.0, 0.08)
	settle.tween_property(right_charge, "modulate:a", 0.0, 0.08)
	settle.tween_property(main_gun, "scale", Vector2.ONE, 0.04)
	settle.tween_property(main_charge, "modulate:a", 0.0, 0.08)
	await settle.finished


func retract():

	if not deployed:
		return

	deployed = false

	var discharge = create_tween()
	discharge.set_parallel(true)
	discharge.tween_property(left_charge, "modulate:a", 0.0, 0.08)
	discharge.tween_property(right_charge, "modulate:a", 0.0, 0.08)
	await discharge.finished

	var collapse = create_tween()
	collapse.set_parallel(true)
	collapse.set_trans(Tween.TRANS_QUAD)
	collapse.set_ease(Tween.EASE_IN)
	collapse.tween_property(left_gun, "position", Vector2(10, 4), 0.25)
	collapse.tween_property(right_gun, "position", Vector2(-10, 4), 0.25)
	collapse.tween_property(left_gun, "rotation", 1.20, 0.25)
	collapse.tween_property(right_gun, "rotation", -1.20, 0.25)
	collapse.tween_property(left_gun, "scale", Vector2(0.25, 0.25), 0.25)
	collapse.tween_property(right_gun, "scale", Vector2(0.25, 0.25), 0.25)
	collapse.tween_property(left_gun, "modulate:a", 0.0, 0.18)
	collapse.tween_property(right_gun, "modulate:a", 0.0, 0.18)
	await collapse.finished

	var covers = create_tween()
	covers.set_parallel(true)
	covers.tween_property(left_mount_plate, "rotation", 0.0, 0.12)
	covers.tween_property(right_mount_plate, "rotation", 0.0, 0.12)
	await covers.finished


func fire_muzzles():

	play_muzzle_flash(main_fire)
	if plasma_level >= 2:
		play_muzzle_flash(left_fire)
		play_muzzle_flash(right_fire)


func set_combo_chain_rank(rank_index):

	combo_chain_rank = rank_index
	update_muzzle_tint()


func update_muzzle_tint():

	var muzzle_brightness = 1.0

	if combo_chain_rank >= 7:
		muzzle_brightness = 1.42
	elif combo_chain_rank >= 5:
		muzzle_brightness = 1.30
	elif combo_chain_rank >= 2:
		muzzle_brightness = 1.18
	if plasma_level >= 3:
		muzzle_brightness *= 1.08
	if plasma_evolution == &"overcharge":
		muzzle_brightness *= 1.20
	elif plasma_evolution == &"ricochet":
		muzzle_brightness *= 1.16
	if OS.has_feature("mobile"):
		muzzle_brightness *= 1.12

	var tint = Color(
		muzzle_brightness,
		muzzle_brightness * (0.96 if plasma_evolution == &"overcharge" else 1.0),
		muzzle_brightness * (0.62 if plasma_evolution == &"overcharge" else 1.0),
		1.0
	)
	if plasma_evolution == &"ricochet":
		tint = Color(muzzle_brightness * 0.74, muzzle_brightness, muzzle_brightness * 1.12, 1.0)
	left_fire.self_modulate = tint
	right_fire.self_modulate = tint
	main_fire.self_modulate = tint


func play_fire_sound():

	var player = fire_sound_players[next_fire_sound]
	next_fire_sound = (next_fire_sound + 1) % fire_sound_players.size()
	player.pitch_scale = randf_range(0.97, 1.03)
	player.play()


func play_muzzle_flash(fire_effect):

	fire_effect.modulate.a = 1.0
	var start_scale := 0.105
	var end_scale := 0.075
	var duration := 0.09
	if plasma_evolution == &"overcharge":
		start_scale = 0.132
		end_scale = 0.088
		duration = 0.11
	elif plasma_evolution == &"ricochet":
		start_scale = 0.122
		end_scale = 0.080
		duration = 0.105
	if OS.has_feature("mobile"):
		start_scale *= 1.20
		end_scale *= 1.20
	fire_effect.scale = Vector2(start_scale, start_scale)

	var flash = create_tween()
	flash.set_parallel(true)
	flash.tween_property(fire_effect, "modulate:a", 0.0, duration)
	flash.tween_property(fire_effect, "scale", Vector2(end_scale, end_scale), duration)
