extends Node2D


class StarLayerData:
	var positions := PackedVector2Array()
	var base_alphas := PackedFloat32Array()
	var twinkle_phases := PackedFloat32Array()
	var twinkle_speeds := PackedFloat32Array()
	var twinkle_amounts := PackedFloat32Array()
	var count: int
	var speed: float
	var radius_min: float
	var radius_max: float
	var color: Color
	var radii := PackedFloat32Array()

	func _init(
		star_count: int,
		layer_speed: float,
		minimum_radius: float,
		maximum_radius: float,
		layer_color: Color
	) -> void:
		count = star_count
		speed = layer_speed
		radius_min = minimum_radius
		radius_max = maximum_radius
		color = layer_color


@export_range(1, 100, 1) var far_star_count := 48
@export_range(1, 100, 1) var mid_star_count := 26
@export_range(1, 100, 1) var near_star_count := 14
@export var far_speed := 4.0
@export var mid_speed := 10.0
@export var near_speed := 22.0
@export var shooting_star_interval_min := 15.0
@export var shooting_star_interval_max := 25.0
@export_range(1.0, 1.15, 0.01) var sector_intensity_multiplier := 1.0

var layers: Array[StarLayerData] = []
var viewport_size := Vector2.ZERO
var random := RandomNumberGenerator.new()
var cluster_centers := PackedVector2Array()
var shooting_star_wait := 0.0
var shooting_star_active := false
var shooting_star_elapsed := 0.0
var shooting_star_duration := 0.65
var shooting_star_start := Vector2.ZERO
var shooting_star_end := Vector2.ZERO


func _ready() -> void:
	z_index = -8
	random.randomize()
	viewport_size = get_viewport_rect().size
	initialize_cluster_centers()
	layers = [
		StarLayerData.new(far_star_count, far_speed, 0.55, 0.85, Color(0.30, 0.48, 0.68, 1.0)),
		StarLayerData.new(mid_star_count, mid_speed, 0.80, 1.25, Color(0.38, 0.63, 0.82, 1.0)),
		StarLayerData.new(near_star_count, near_speed, 1.20, 1.85, Color(0.52, 0.74, 0.90, 1.0)),
	]
	for layer in layers:
		initialize_layer(layer)
	shooting_star_wait = random.randf_range(shooting_star_interval_min, shooting_star_interval_max)
	queue_redraw()


func initialize_cluster_centers() -> void:
	cluster_centers.clear()
	for cluster_index in range(5):
		cluster_centers.append(Vector2(
			random.randf_range(viewport_size.x * 0.08, viewport_size.x * 0.92),
			random.randf_range(viewport_size.y * 0.08, viewport_size.y * 0.92)
		))


func get_clustered_position() -> Vector2:
	# Çoğunluk küçük kümelere yaklaşır; kalan yıldızlar geniş boşlukları tamamen yapay bırakmaz.
	if random.randf() < 0.68:
		var center := cluster_centers[random.randi_range(0, cluster_centers.size() - 1)]
		return Vector2(
			fposmod(random.randfn(center.x, viewport_size.x * 0.075), viewport_size.x),
			fposmod(random.randfn(center.y, viewport_size.y * 0.10), viewport_size.y)
		)
	return Vector2(
		random.randf_range(0.0, viewport_size.x),
		random.randf_range(0.0, viewport_size.y)
	)


func initialize_layer(layer: StarLayerData) -> void:
	for star_index in range(layer.count):
		layer.positions.append(get_clustered_position())
		layer.radii.append(random.randf_range(layer.radius_min, layer.radius_max))
		var star_alpha := random.randf_range(0.20, 0.38)
		if random.randf() < 0.06:
			star_alpha = minf(star_alpha * 1.45, 0.52)
		layer.base_alphas.append(star_alpha)
		layer.twinkle_phases.append(random.randf_range(0.0, TAU))
		# Yıldızların yalnızca yaklaşık %20'si yavaşça twinkle yapar.
		if random.randf() < 0.20:
			layer.twinkle_speeds.append(random.randf_range(0.75, 1.45))
			layer.twinkle_amounts.append(random.randf_range(0.08, 0.18))
		else:
			layer.twinkle_speeds.append(0.0)
			layer.twinkle_amounts.append(0.0)


func _process(delta: float) -> void:
	var current_viewport_size := get_viewport_rect().size
	if current_viewport_size != viewport_size:
		viewport_size = current_viewport_size

	for layer in layers:
		for star_index in range(layer.count):
			var star_position := layer.positions[star_index]
			star_position.y += layer.speed * delta
			if star_position.y > viewport_size.y + 2.0:
				star_position.y = -2.0
			layer.positions[star_index] = star_position
			if layer.twinkle_speeds[star_index] > 0.0:
				layer.twinkle_phases[star_index] = fmod(
					layer.twinkle_phases[star_index]
					+ layer.twinkle_speeds[star_index] * delta,
					TAU
				)
	update_shooting_star(delta)
	queue_redraw()


func update_shooting_star(delta: float) -> void:
	if shooting_star_active:
		shooting_star_elapsed += delta
		if shooting_star_elapsed >= shooting_star_duration:
			shooting_star_active = false
			shooting_star_wait = random.randf_range(
				shooting_star_interval_min,
				shooting_star_interval_max
			)
		return

	shooting_star_wait -= delta
	if shooting_star_wait <= 0.0:
		start_shooting_star()


func start_shooting_star() -> void:
	shooting_star_active = true
	shooting_star_elapsed = 0.0
	shooting_star_duration = random.randf_range(0.50, 0.80)
	var from_left := random.randf() < 0.5
	var start_x := (
		random.randf_range(-60.0, viewport_size.x * 0.30)
		if from_left
		else random.randf_range(viewport_size.x * 0.70, viewport_size.x + 60.0)
	)
	shooting_star_start = Vector2(
		start_x,
		random.randf_range(viewport_size.y * 0.08, viewport_size.y * 0.48)
	)
	var horizontal_distance := random.randf_range(260.0, 430.0) * (1.0 if from_left else -1.0)
	shooting_star_end = shooting_star_start + Vector2(
		horizontal_distance,
		random.randf_range(120.0, 230.0)
	)


func _draw() -> void:
	draw_shooting_star()
	for layer in layers:
		for star_index in range(layer.count):
			var alpha := layer.base_alphas[star_index]
			var twinkle_amount := layer.twinkle_amounts[star_index]
			if twinkle_amount > 0.0:
				alpha *= 1.0 + sin(layer.twinkle_phases[star_index]) * twinkle_amount
			if OS.has_feature("mobile"):
				alpha = minf(alpha * 1.08, 0.58)
			alpha = minf(alpha * sector_intensity_multiplier, 0.62)
			var star_color := Color(layer.color.r, layer.color.g, layer.color.b, alpha)
			draw_circle(layer.positions[star_index], layer.radii[star_index], star_color)


func draw_shooting_star() -> void:
	if not shooting_star_active:
		return
	var progress := clampf(shooting_star_elapsed / shooting_star_duration, 0.0, 1.0)
	var head_position := shooting_star_start.lerp(shooting_star_end, progress)
	var travel_direction := (shooting_star_end - shooting_star_start).normalized()
	var life_fade := sin(progress * PI)
	var trail_length := 105.0
	var segment_count := 7
	for segment_index in range(segment_count):
		var start_ratio := float(segment_index) / float(segment_count)
		var end_ratio := float(segment_index + 1) / float(segment_count)
		var segment_start := head_position - travel_direction * trail_length * start_ratio
		var segment_end := head_position - travel_direction * trail_length * end_ratio
		var segment_alpha := (1.0 - start_ratio) * 0.22 * life_fade
		draw_line(
			segment_start,
			segment_end,
			Color(0.62, 0.82, 0.94, segment_alpha),
			0.85,
			true
		)
	draw_circle(head_position, 1.45, Color(0.76, 0.90, 0.98, 0.38 * life_fade))
