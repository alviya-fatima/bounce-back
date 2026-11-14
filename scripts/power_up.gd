extends Area2D
class_name PowerUp

const TYPES := {
	"wide": {"color": Color(0.3, 0.85, 1.0), "letter": "W"},
	"multi": {"color": Color(1.0, 0.45, 0.75), "letter": "M"},
	"slow": {"color": Color(0.45, 1.0, 0.6), "letter": "S"},
	"shield": {"color": Color(0.55, 0.85, 1.0), "letter": "B"},
	"life": {"color": Color(1.0, 0.35, 0.4), "letter": "+"},
}

var kind := "wide"
var fall_speed := 165.0
var age := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	add_to_group("powerup")
	queue_redraw()

func setup(power_kind: String) -> void:
	kind = power_kind
	queue_redraw()

func _physics_process(delta: float) -> void:
	age += delta
	position.y += fall_speed * delta
	rotation = sin(age * 4.0) * 0.18
	queue_redraw()
	if global_position.y > 700.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("paddle"):
		get_tree().call_group("game", "apply_power_up", kind)
		queue_free()

func _draw() -> void:
	var info: Dictionary = TYPES[kind]
	var col: Color = info["color"]
	var letter: String = info["letter"]
	var pulse := 1.0 + sin(age * 6.0) * 0.06
	draw_circle(Vector2.ZERO, 22.0 * pulse, Color(col.r, col.g, col.b, 0.12))
	draw_circle(Vector2.ZERO, 17.0 * pulse, Color(0.04, 0.07, 0.12, 0.95))
	draw_arc(Vector2.ZERO, 17.0 * pulse, 0.0, TAU, 28, col, 2.5, true)
	draw_string(ThemeDB.fallback_font, Vector2(-17.0, 7.0), letter, HORIZONTAL_ALIGNMENT_CENTER, 34.0, 20, col)
