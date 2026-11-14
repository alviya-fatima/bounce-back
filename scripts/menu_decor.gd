extends Control

const ARENA := Rect2(64.0, 64.0, 1024.0, 528.0)
const PADDLE_Y := 590.0
const BALL_RADIUS := 8.0

var ball_pos := Vector2(820.0, 380.0)
var ball_vel := Vector2(-250.0, -190.0)
var paddle_x := 820.0
var trail: Array[Vector2] = []
var dust: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for i in 34:
		dust.append({
			"pos": Vector2(rng.randf_range(0.0, 1152.0), rng.randf_range(0.0, 648.0)),
			"r": rng.randf_range(0.6, 1.8),
			"speed": rng.randf_range(4.0, 16.0),
			"phase": rng.randf_range(0.0, TAU),
		})

func _process(delta: float) -> void:
	ball_pos += ball_vel * delta
	if ball_pos.x < ARENA.position.x + BALL_RADIUS or ball_pos.x > ARENA.end.x - BALL_RADIUS:
		ball_vel.x = -ball_vel.x
		ball_pos.x = clampf(ball_pos.x, ARENA.position.x + BALL_RADIUS, ARENA.end.x - BALL_RADIUS)
	if ball_pos.y < ARENA.position.y + BALL_RADIUS:
		ball_vel.y = absf(ball_vel.y)
		ball_pos.y = ARENA.position.y + BALL_RADIUS
	var paddle_target := clampf(ball_pos.x, ARENA.position.x + 70.0, ARENA.end.x - 70.0)
	paddle_x = lerpf(paddle_x, paddle_target, clampf(delta * 3.0, 0.0, 1.0))
	if ball_pos.y > PADDLE_Y - 12.0 and ball_vel.y > 0.0:
		if absf(ball_pos.x - paddle_x) < 80.0:
			ball_vel.y = -absf(ball_vel.y)
			ball_vel.x += (ball_pos.x - paddle_x) * 3.0
			ball_pos.y = PADDLE_Y - 12.0
		elif ball_pos.y > ARENA.end.y - BALL_RADIUS:
			ball_pos.y = ARENA.end.y - BALL_RADIUS
			ball_vel.y = -absf(ball_vel.y)
	trail.push_front(ball_pos)
	if trail.size() > 22:
		trail.pop_back()
	for i in dust.size():
		var d: Dictionary = dust[i]
		var p: Vector2 = d["pos"] + Vector2(0.0, -d["speed"] * delta)
		if p.y < -4.0:
			p.y = 652.0
		d["pos"] = p
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1152.0, 648.0), Color(0.043, 0.055, 0.102))
	draw_rect(Rect2(0.0, 0.0, 1152.0, 324.0), Color(0.055, 0.075, 0.135, 0.6))
	for i in range(0, 1153, 72):
		draw_line(Vector2(i, 0.0), Vector2(i, 648.0), Color(0.3, 0.6, 1.0, 0.025), 1.0)
	for j in range(0, 649, 72):
		draw_line(Vector2(0.0, j), Vector2(1152.0, j), Color(0.3, 0.6, 1.0, 0.025), 1.0)
	draw_rect(ARENA, Color(0.3, 0.75, 1.0, 0.08), false, 2.0)
	for d in dust:
		draw_circle(d["pos"], d["r"], Color(0.5, 0.8, 1.0, 0.10))
	for i in range(1, trail.size()):
		var k := 1.0 - float(i) / float(trail.size())
		draw_line(trail[i - 1], trail[i], Color(0.35, 0.9, 1.0, k * 0.30), 7.0 * k + 1.0)
	draw_circle(ball_pos, BALL_RADIUS + 8.0, Color(0.35, 0.9, 1.0, 0.07))
	draw_circle(ball_pos, BALL_RADIUS, Color(0.8, 0.97, 1.0, 0.45))
	draw_circle(ball_pos + Vector2(-2.5, -2.5), 2.6, Color(1.0, 1.0, 1.0, 0.5))
	var w := 140.0
	var h := 16.0
	draw_rect(Rect2(paddle_x - w * 0.5 - 5.0, PADDLE_Y - h * 0.5 - 5.0, w + 10.0, h + 10.0), Color(0.2, 0.85, 1.0, 0.06))
	draw_circle(Vector2(paddle_x - w * 0.5 + h * 0.5, PADDLE_Y), h * 0.5, Color(0.25, 0.85, 1.0, 0.5))
	draw_circle(Vector2(paddle_x + w * 0.5 - h * 0.5, PADDLE_Y), h * 0.5, Color(0.25, 0.85, 1.0, 0.5))
	draw_rect(Rect2(paddle_x - w * 0.5 + h * 0.5, PADDLE_Y - h * 0.5, w - h, h), Color(0.25, 0.85, 1.0, 0.5))
