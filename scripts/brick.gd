extends StaticBody2D
class_name Brick

signal destroyed(brick: Brick)

const COLORS := [
	Color(0.0, 0.0, 0.0),
	Color(1.0, 0.42, 0.42),
	Color(1.0, 0.7, 0.28),
	Color(0.69, 0.52, 1.0),
	Color(0.3, 0.84, 1.0),
]

const POINTS := [0, 60, 120, 200, 300]

var hp := 1
var max_hp := 1
var base_color := Color(1.0, 0.42, 0.42)
var points := 60
var flash := 0.0
var wobble := 0.0
var style: StyleBoxFlat

func _ready() -> void:
	style = StyleBoxFlat.new()
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.corner_detail = 5
	style.anti_aliasing = true
	add_to_group("brick")
	queue_redraw()

func setup(hit_points: int) -> void:
	max_hp = clampi(hit_points, 1, 4)
	hp = max_hp
	base_color = COLORS[hp]
	points = POINTS[hp]
	flash = 0.0
	wobble = 0.0
	queue_redraw()

func hit() -> void:
	hp -= 1
	wobble = 1.0
	if hp <= 0:
		destroyed.emit(self)
		queue_free()
		return
	flash = 1.0
	base_color = COLORS[hp]
	points = POINTS[hp]
	Sfx.play("hit", -6.0, randf_range(0.95, 1.1))
	queue_redraw()

func _process(delta: float) -> void:
	if flash > 0.0:
		flash = maxf(flash - delta * 5.0, 0.0)
		queue_redraw()
	if wobble > 0.0:
		wobble = maxf(wobble - delta * 6.0, 0.0)
		queue_redraw()

func _draw() -> void:
	var brick_size := Vector2(84.0, 28.0)
	var color := base_color.lerp(Color(1.0, 1.0, 1.0), flash * 0.7)
	style.bg_color = color
	style.border_color = color.darkened(0.35)
	var jitter := Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5)) * wobble
	draw_set_transform(jitter)
	draw_style_box(style, Rect2(-brick_size * 0.5, brick_size))
	draw_rect(Rect2(-brick_size.x * 0.5 + 10.0, -brick_size.y * 0.5 + 5.0, brick_size.x - 20.0, 4.0), Color(1.0, 1.0, 1.0, 0.35))
	draw_rect(Rect2(-brick_size.x * 0.5 + 10.0, brick_size.y * 0.5 - 9.0, brick_size.x - 20.0, 3.0), Color(0.0, 0.0, 0.0, 0.18))
	if max_hp > 1:
		for i in max_hp:
			var on := i < hp
			var px := -float(max_hp - 1) * 5.0 + float(i) * 10.0
			draw_circle(Vector2(px, 0.0), 2.2, Color(1.0, 1.0, 1.0, 0.9) if on else Color(0.0, 0.0, 0.0, 0.25))
