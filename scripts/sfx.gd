extends Node

const POOL_SIZE := 12

var streams := {
	"bounce": preload("res://assets/sounds/bounce.wav"),
	"paddle": preload("res://assets/sounds/paddle.wav"),
	"hit": preload("res://assets/sounds/hit.wav"),
	"break": preload("res://assets/sounds/break.wav"),
	"launch": preload("res://assets/sounds/launch.wav"),
	"power": preload("res://assets/sounds/power.wav"),
	"lose": preload("res://assets/sounds/lose.wav"),
	"win": preload("res://assets/sounds/win.wav"),
	"gameover": preload("res://assets/sounds/gameover.wav"),
	"click": preload("res://assets/sounds/click.wav"),
}

var players: Array[AudioStreamPlayer] = []
var next_index := 0
var muted := false
var toast: Label
var toast_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		players.append(player)
	_build_toast()

func _build_toast() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	toast = Label.new()
	toast.position = Vector2(24.0, 610.0)
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_theme_font_size_override("font_size", 16)
	toast.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	toast.add_theme_constant_override("shadow_offset_x", 2)
	toast.add_theme_constant_override("shadow_offset_y", 2)
	toast.modulate.a = 0.0
	layer.add_child(toast)

func play(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if muted or not streams.has(sound_name):
		return
	var player := players[next_index]
	next_index = (next_index + 1) % players.size()
	player.stream = streams[sound_name]
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()

func toggle_mute() -> void:
	muted = not muted
	if muted:
		for player in players:
			player.stop()
	toast.text = "SOUND OFF" if muted else "SOUND ON"
	toast.add_theme_color_override("font_color", Color(1.0, 0.65, 0.7) if muted else Color(0.75, 0.92, 1.0))
	toast.modulate.a = 1.0
	if toast_tween:
		toast_tween.kill()
	toast_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	toast_tween.tween_interval(0.7)
	toast_tween.tween_property(toast, "modulate:a", 0.0, 0.35)

func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_M or key.physical_keycode == KEY_M:
		toggle_mute()
		get_viewport().set_input_as_handled()
