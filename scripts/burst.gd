extends Node2D

var particles: Array = []

func setup(pos: Vector2, col: Color, count: int = 14, power: float = 260.0) -> void:
	global_position = pos
	for i in count:
		var angle := randf() * TAU
		var spd := randf_range(power * 0.25, power)
		particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * spd,
			"size": randf_range(2.0, 5.5),
			"life": randf_range(0.3, 0.65),
			"age": 0.0,
			"color": col,
		})
	queue_redraw()

func _process(delta: float) -> void:
	var alive := false
	for p in particles:
		var age: float = p["age"] + delta
		p["age"] = age
		if age >= p["life"]:
			continue
		alive = true
		var vel: Vector2 = p["vel"]
		p["vel"] = vel * (1.0 - clampf(delta * 3.0, 0.0, 1.0))
		p["pos"] = p["pos"] + p["vel"] * delta
	queue_redraw()
	if not alive:
		queue_free()

func _draw() -> void:
	for p in particles:
		var age: float = p["age"]
		var life: float = p["life"]
		if age >= life:
			continue
		var k := 1.0 - age / life
		var col: Color = p["color"]
		draw_circle(p["pos"], p["size"] * (0.4 + k * 0.6), Color(col.r, col.g, col.b, k))
