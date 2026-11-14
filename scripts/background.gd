extends Node2D

var dust: Array = []

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 40:
		dust.append({
			"pos": Vector2(rng.randf_range(40.0, 1112.0), rng.randf_range(72.0, 644.0)),
			"r": rng.randf_range(0.6, 1.7),
			"speed": rng.randf_range(3.0, 12.0),
		})

func _process(delta: float) -> void:
	for d in dust:
		var p: Vector2 = d["pos"]
		p.y -= d["speed"] * delta
		if p.y < 68.0:
			p.y = 644.0
		d["pos"] = p
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1152.0, 648.0), Color(0.043, 0.055, 0.102))
	draw_rect(Rect2(0.0, 0.0, 1152.0, 300.0), Color(0.055, 0.075, 0.135, 0.5))
	for i in range(0, 1153, 64):
		draw_line(Vector2(i, 64.0), Vector2(i, 648.0), Color(0.3, 0.6, 1.0, 0.022), 1.0)
	for j in range(64, 649, 64):
		draw_line(Vector2(0.0, j), Vector2(1152.0, j), Color(0.3, 0.6, 1.0, 0.022), 1.0)
	for d in dust:
		draw_circle(d["pos"], d["r"], Color(0.5, 0.8, 1.0, 0.09))
	var glow := Color(0.25, 0.75, 1.0, 0.10)
	draw_line(Vector2(32.0, 64.0), Vector2(1120.0, 64.0), glow, 2.0)
	draw_line(Vector2(32.0, 64.0), Vector2(32.0, 648.0), glow, 2.0)
	draw_line(Vector2(1120.0, 64.0), Vector2(1120.0, 648.0), glow, 2.0)
	draw_rect(Rect2(32.0, 64.0, 1088.0, 584.0), Color(0.25, 0.75, 1.0, 0.03))
