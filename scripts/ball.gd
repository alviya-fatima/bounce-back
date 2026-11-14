extends CharacterBody2D
class_name Ball

signal lost(ball: Ball)
signal paddle_bounced

const RADIUS := 9.0
const MAX_SPEED := 880.0
const TRAIL_LENGTH := 20
const GLOW := Color(0.35, 0.88, 1.0)

var paddle: Paddle
var speed := 430.0
var speed_multiplier := 1.0
var stuck := true
var squash := 1.0
var trail: Line2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	add_to_group("ball")
	trail = Line2D.new()
	trail.top_level = true
	trail.width = 9.0
	trail.joint_mode = Line2D.LINE_JOINT_ROUND
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	trail.z_index = -1
	var gradient := Gradient.new()
	gradient.set_color(0, Color(GLOW.r, GLOW.g, GLOW.b, 0.0))
	gradient.set_color(1, Color(GLOW.r, GLOW.g, GLOW.b, 0.4))
	trail.gradient = gradient
	add_child(trail)
	queue_redraw()

func configure(pad: Paddle, base_speed: float, slowed: bool) -> void:
	paddle = pad
	speed = base_speed
	speed_multiplier = 0.72 if slowed else 1.0

func attach() -> void:
	stuck = true
	velocity = Vector2.ZERO
	squash = 1.0
	trail.clear_points()
	queue_redraw()

func launch(dir: Vector2 = Vector2.ZERO) -> void:
	if dir == Vector2.ZERO:
		dir = Vector2(randf_range(-0.3, 0.3), -1.0)
	stuck = false
	velocity = dir.normalized() * speed * speed_multiplier
	trail.clear_points()
	squash = 1.3
	queue_redraw()

func bounce_back() -> void:
	global_position.y = 600.0
	velocity.y = -absf(velocity.y)
	_safe_direction()
	squash = 1.3
	queue_redraw()

func set_speed_multiplier(multiplier: float) -> void:
	speed_multiplier = multiplier
	if stuck:
		return
	var dir := velocity.normalized()
	if dir == Vector2.ZERO:
		return
	velocity = dir * speed * speed_multiplier

func _process(delta: float) -> void:
	if squash != 1.0:
		squash = move_toward(squash, 1.0, delta * 3.2)
		queue_redraw()

func _physics_process(delta: float) -> void:
	if stuck:
		if paddle:
			global_position = paddle.global_position + Vector2(0.0, -(paddle.height * 0.5 + RADIUS + 7.0))
		trail.clear_points()
		return
	var collision := move_and_collide(velocity * delta)
	if collision:
		_handle_collision(collision)
	trail.add_point(global_position)
	while trail.get_point_count() > TRAIL_LENGTH:
		trail.remove_point(0)
	if global_position.y > 700.0:
		lost.emit(self)

func _handle_collision(collision: KinematicCollision2D) -> void:
	var collider := collision.get_collider() as Node
	var normal := collision.get_normal()
	if collider and collider.is_in_group("paddle"):
		_bounce_off_paddle(collider as Paddle)
		paddle_bounced.emit()
		squash = 1.35
		queue_redraw()
		Sfx.play("paddle", -2.0, randf_range(0.95, 1.08))
		return
	if collider is Brick:
		(collider as Brick).hit()
	velocity = velocity.bounce(normal)
	_safe_direction()
	global_position += normal * 1.5
	squash = 1.3
	queue_redraw()
	Sfx.play("bounce", -9.0, randf_range(0.9, 1.2))

func _bounce_off_paddle(pad: Paddle) -> void:
	var half := pad.width * 0.5
	var offset := clampf((global_position.x - pad.global_position.x) / half, -1.0, 1.0)
	var angle := offset * deg_to_rad(62.0)
	var dir := Vector2(sin(angle), -cos(angle))
	speed = minf(speed + 6.0, MAX_SPEED)
	velocity = dir * speed * speed_multiplier
	global_position.y = minf(global_position.y, pad.global_position.y - pad.height * 0.5 - RADIUS - 1.0)
	pad.pulse()

func _safe_direction() -> void:
	var spd := velocity.length()
	if spd < 1.0:
		return
	var dir := velocity / spd
	if absf(dir.y) < 0.28:
		dir.y = -0.28 if dir.y <= 0.0 else 0.28
	if absf(dir.x) < 0.12:
		dir.x = 0.12 if dir.x >= 0.0 else -0.12
	velocity = dir.normalized() * spd

func _draw() -> void:
	var r := RADIUS * squash
	draw_circle(Vector2.ZERO, r + 7.0, Color(GLOW.r, GLOW.g, GLOW.b, 0.09))
	draw_circle(Vector2.ZERO, r + 3.0, Color(GLOW.r, GLOW.g, GLOW.b, 0.16))
	draw_circle(Vector2.ZERO, r, Color(0.82, 0.97, 1.0))
	draw_circle(Vector2(-r * 0.32, -r * 0.32), r * 0.34, Color(1.0, 1.0, 1.0, 0.95))
