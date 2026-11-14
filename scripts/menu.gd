extends Control

const GAME_SCENE := "res://scenes/game.tscn"
const SCORE_PATH := "user://scores.cfg"

var starting := false

@onready var play_button: Button = $PlayButton
@onready var quit_button: Button = $QuitButton
@onready var high_label: Label = $HighScoreLabel
@onready var title: Label = $Title

func _ready() -> void:
	play_button.pressed.connect(_start_game)
	quit_button.pressed.connect(_quit)
	_load_high_score()
	play_button.grab_focus()
	_center_title_pivot.call_deferred()
	var pulse := create_tween().set_loops()
	pulse.tween_property(title, "scale", Vector2(1.025, 1.025), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(title, "scale", Vector2.ONE, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _center_title_pivot() -> void:
	title.pivot_offset = Vector2(576.0, 56.0)

func _load_high_score() -> void:
	var cfg := ConfigFile.new()
	var best := 0
	if cfg.load(SCORE_PATH) == OK:
		best = int(cfg.get_value("scores", "high", 0))
	high_label.text = "BEST  %d" % best

func _start_game() -> void:
	if starting:
		return
	starting = true
	Sfx.play("click")
	get_tree().change_scene_to_file(GAME_SCENE)

func _quit() -> void:
	Sfx.play("click")
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not starting:
		_start_game()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()
