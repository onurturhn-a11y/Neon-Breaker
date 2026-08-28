class_name CollectibleMagnetMotion
extends RefCounted


const MIN_PULL_SPEED = 450.0
const MAX_PULL_SPEED = 600.0

var velocity = Vector2.ZERO


func move_collectible(collectible, paddle, fall_speed, delta):

	if not is_instance_valid(paddle):
		collectible.global_position.y += fall_speed * delta
		return

	var to_paddle = paddle.global_position - collectible.global_position
	var distance = to_paddle.length()
	if distance <= 0.01:
		return

	var proximity = 1.0 - clampf(distance / 700.0, 0.0, 1.0)
	var pull_speed = lerpf(MIN_PULL_SPEED, MAX_PULL_SPEED, proximity)
	var desired_velocity = to_paddle.normalized() * pull_speed

	if velocity == Vector2.ZERO:
		velocity = Vector2.DOWN * fall_speed

	velocity = velocity.lerp(desired_velocity, minf(delta * 6.0, 1.0))
	collectible.global_position += velocity * delta


func reset():

	velocity = Vector2.ZERO
