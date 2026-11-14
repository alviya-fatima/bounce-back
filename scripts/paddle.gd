extends CharacterBody2D
class_name Paddle

const BASE_WIDTH := 140.0
const HEIGHT := 18.0
const SPEED := 1600.0
const MIN_X := 32.0
const MAX_X := 1120.0

var width := BASE_WIDTH
var height := HEIGHT
var target_width := BASE_WIDTH
var glow := 0.0

@onready var shape_node: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("paddle")
	collision_mask = 0
	_apply_width()

func _physics_process(delta: float) -> void:
	if absf(width - target_width) > 0.5:
		width = lerpf(width, target_width, clampf(delta * 9.0, 0.0, 1.0))
		_apply_width()
	var dir := Input.get_axis("ui_left", "ui_right")
	if dir == 0.0:
		var left := Input.is_key_pressed(KEY_A)
		var right := Input.is_key_pressed(KEY_D)
		dir = (1.0 if right else 0.0) - (1.0 if left else 0.0)
	if dir != 0.0:
		velocity.x = dir * SPEED
	else:
		var diff := get_global_mouse_position().x - global_position.x
		velocity.x = clampf(diff * 14.0, -SPEED, SPEED)
		if absf(diff) < 1.5:
			velocity.x = 0.0
	move_and_slide()
	global_position.x = clampf(global_position.x, MIN_X + width * 0.5, MAX_X - width * 0.5)
	global_position.y = 596.0
	if glow > 0.0:
		glow = maxf(glow - delta * 4.5, 0.0)
		queue_redraw()

func _apply_width() -> void:
	(shape_node.shape as RectangleShape2D).size = Vector2(width, HEIGHT)
	queue_redraw()

func pulse() -> void:
	glow = 1.0
	queue_redraw()

func reset() -> void:
	target_width = BASE_WIDTH
	width = BASE_WIDTH
	_apply_width()

func _draw() -> void:
	var w := width
	var h := HEIGHT
	var glow_alpha := 0.10 + glow * 0.18
	draw_rect(Rect2(-w * 0.5 - 6.0, -h * 0.5 - 6.0, w + 12.0, h + 12.0), Color(0.25, 0.85, 1.0, glow_alpha))
	draw_rect(Rect2(-w * 0.5 - 3.0, -h * 0.5 - 3.0, w + 6.0, h + 6.0), Color(0.25, 0.85, 1.0, glow_alpha + 0.06))
	var body := Color(0.22, 0.82, 1.0)
	var radius := h * 0.5
	draw_circle(Vector2(-w * 0.5 + radius, 0.0), radius, body)
	draw_circle(Vector2(w * 0.5 - radius, 0.0), radius, body)
	draw_rect(Rect2(-w * 0.5 + radius, -radius, w - radius * 2.0, h), body)
	draw_rect(Rect2(-w * 0.5 + radius, -radius + 3.0, w - radius * 2.0, 4.0), Color(1.0, 1.0, 1.0, 0.5))
	draw_circle(Vector2(-w * 0.5 + radius, 0.0), radius * 0.45, Color(0.8, 0.98, 1.0, 0.9))
	draw_circle(Vector2(w * 0.5 - radius, 0.0), radius * 0.45, Color(0.8, 0.98, 1.0, 0.9))
