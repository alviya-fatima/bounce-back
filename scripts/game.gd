extends Node2D

const BallScene: PackedScene = preload("res://scenes/ball.tscn")
const BrickScene: PackedScene = preload("res://scenes/brick.tscn")
const PowerUpScene: PackedScene = preload("res://scenes/power_up.tscn")
const BurstScene: PackedScene = preload("res://scenes/burst.tscn")

const NORMAL_WIDTH := 140.0
const WIDE_WIDTH := 215.0
const START_LIVES := 3
const BASE_BALL_SPEED := 430.0
const CELL := Vector2(96.0, 40.0)
const BRICK_SIZE := Vector2(84.0, 28.0)
const SCORE_PATH := "user://scores.cfg"
const MAX_COMBO := 5

const PATTERNS := [
	[
		"1111111111",
		"1111111111",
		"1111111111",
	],
	[
		".11111111.",
		"1122222211",
		".11111111.",
		"..111111..",
	],
	[
		"2222222222",
		"2........2",
		"2.111111.2",
		"2.1....1.2",
		"2.111111.2",
		"2222222222",
	],
	[
		"1..1..1..1",
		".11.11.11.",
		"1111111111",
		".11.11.11.",
		"1..1..1..1",
	],
	[
		"1212121212",
		"2121212121",
		"1212121212",
		"2121212121",
	],
]

const POWER_NAMES := {
	"wide": "WIDE PADDLE",
	"multi": "MULTI BALL",
	"slow": "SLOW MOTION",
	"shield": "SAFE BOUNCE",
	"life": "+1 LIFE",
}

enum State { READY, PLAYING, CLEARED, GAMEOVER }

@onready var paddle: Paddle = $Paddle
@onready var bricks: Node2D = $Bricks
@onready var balls: Node2D = $Balls
@onready var powerups: Node2D = $PowerUps
@onready var bursts: Node2D = $Bursts
@onready var shield_line: Line2D = $Shield
@onready var camera: Camera2D = $Camera2D
@onready var score_label: Label = $HUD/Root/ScoreLabel
@onready var level_label: Label = $HUD/Root/LevelLabel
@onready var lives_label: Label = $HUD/Root/LivesLabel
@onready var combo_label: Label = $HUD/Root/ComboLabel
@onready var banner: Label = $HUD/Root/BannerLabel
@onready var hint: Label = $HUD/Root/HintLabel
@onready var pause_overlay = $HUD/PauseOverlay
@onready var end_overlay: Control = $HUD/EndOverlay
@onready var end_score: Label = $HUD/EndOverlay/Panel/FinalScore
@onready var end_best: Label = $HUD/EndOverlay/Panel/BestScore
@onready var retry_button: Button = $HUD/EndOverlay/Panel/RetryButton
@onready var menu_button: Button = $HUD/EndOverlay/Panel/MenuButton

var state: int = State.READY
var score := 0
var lives := START_LIVES
var level := 1
var high_score := 0
var remaining_bricks := 0
var active_balls: Array[Ball] = []
var wide_time := 0.0
var slow_time := 0.0
var shield := false
var combo := 0
var shake := 0.0
var banner_tween: Tween = null
var score_tween: Tween = null

func _ready() -> void:
	add_to_group("game")
	_load_high_score()
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	paddle.process_physics_priority = -10
	_update_hud()
	build_level(level)
	_spawn_ball()
	show_banner("LEVEL %d" % level, Color(0.55, 0.95, 1.0), 1.1)

func _process(delta: float) -> void:
	if wide_time > 0.0:
		wide_time = maxf(wide_time - delta, 0.0)
		if wide_time == 0.0:
			paddle.target_width = NORMAL_WIDTH
	if slow_time > 0.0:
		slow_time = maxf(slow_time - delta, 0.0)
		if slow_time == 0.0:
			for b in active_balls:
				b.set_speed_multiplier(1.0)
	if shake > 0.0:
		shake = maxf(shake - delta * 26.0, 0.0)
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake
	elif camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if state != State.GAMEOVER and not pause_overlay.visible:
			pause_overlay.open()
			get_viewport().set_input_as_handled()
		return
	if state == State.READY:
		var launch := event.is_action_pressed("ui_accept")
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				launch = true
		if launch:
			_launch_ball()
			get_viewport().set_input_as_handled()

func _update_hud() -> void:
	score_label.text = "SCORE  %d" % score
	level_label.text = "LEVEL  %d" % level
	lives_label.text = "LIVES  %d" % lives

func _update_combo() -> void:
	combo_label.visible = combo >= 2
	if combo >= 2:
		combo_label.text = "COMBO x%d" % mini(combo, MAX_COMBO)

func _break_combo() -> void:
	combo = 0
	_update_combo()

func _add_score(points: int) -> void:
	score += points
	score_label.text = "SCORE  %d" % score
	if score_tween:
		score_tween.kill()
	score_label.pivot_offset = score_label.size * 0.5
	score_label.scale = Vector2.ONE
	score_tween = create_tween()
	score_tween.tween_property(score_label, "scale", Vector2(1.1, 1.1), 0.06)
	score_tween.tween_property(score_label, "scale", Vector2.ONE, 0.14)

func show_banner(text: String, color: Color, hold: float = 1.2) -> void:
	if banner_tween:
		banner_tween.kill()
	banner.text = text
	banner.add_theme_color_override("font_color", color)
	banner.visible = true
	banner.modulate.a = 1.0
	banner_tween = create_tween()
	banner_tween.tween_interval(hold)
	banner_tween.tween_property(banner, "modulate:a", 0.0, 0.35)
	banner_tween.tween_callback(banner.hide)

func build_level(n: int) -> void:
	for brick in bricks.get_children():
		brick.queue_free()
	remaining_bricks = 0
	var pattern: Array = PATTERNS[(n - 1) % PATTERNS.size()]
	var cycle := int(floor(float(n - 1) / float(PATTERNS.size())))
	for r in pattern.size():
		var row_text: String = pattern[r]
		var cols := row_text.length()
		var used_width := (cols - 1) * CELL.x + BRICK_SIZE.x
		for c in cols:
			var ch := row_text.substr(c, 1)
			if ch == ".":
				continue
			var hp := mini(int(ch) + cycle, 4)
			var brick: Brick = BrickScene.instantiate()
			bricks.add_child(brick)
			var x := 576.0 - used_width * 0.5 + BRICK_SIZE.x * 0.5 + c * CELL.x
			brick.global_position = Vector2(x, 104.0 + r * CELL.y + BRICK_SIZE.y * 0.5)
			brick.setup(hp)
			brick.destroyed.connect(_on_brick_destroyed)
			remaining_bricks += 1
	_update_hud()

func _spawn_ball() -> void:
	var ball: Ball = BallScene.instantiate()
	balls.add_child(ball)
	ball.configure(paddle, BASE_BALL_SPEED + float(level - 1) * 26.0, slow_time > 0.0)
	ball.attach()
	_track_ball(ball)
	hint.visible = true
	state = State.READY

func _track_ball(ball: Ball) -> void:
	active_balls.append(ball)
	ball.lost.connect(_on_ball_lost)
	ball.paddle_bounced.connect(_break_combo)

func _launch_ball() -> void:
	var launched := false
	for b in active_balls:
		if b.stuck:
			b.launch(Vector2(randf_range(-0.28, 0.28), -1.0))
			launched = true
	if launched:
		state = State.PLAYING
		hint.visible = false
		Sfx.play("launch", -3.0)

func _on_ball_lost(ball: Ball) -> void:
	if shield and state == State.PLAYING:
		shield = false
		shield_line.visible = false
		ball.bounce_back()
		_add_shake(5.0)
		Sfx.play("power", -3.0)
		show_banner("BOUNCE BACK!", Color(0.55, 0.9, 1.0), 0.9)
		return
	active_balls.erase(ball)
	ball.queue_free()
	if active_balls.is_empty() and state == State.PLAYING:
		_lose_life.call_deferred()

func _lose_life() -> void:
	if state == State.GAMEOVER or state == State.CLEARED:
		return
	lives -= 1
	_update_hud()
	_add_shake(12.0)
	if lives <= 0:
		_game_over()
		return
	Sfx.play("lose", -2.0)
	_reset_powerups()
	_break_combo()
	show_banner("BOUNCE BACK!", Color(1.0, 0.55, 0.68), 1.3)
	_spawn_ball()

func _reset_powerups() -> void:
	wide_time = 0.0
	slow_time = 0.0
	shield = false
	shield_line.visible = false
	paddle.reset()
	for p in powerups.get_children():
		p.queue_free()

func _game_over() -> void:
	state = State.GAMEOVER
	hint.visible = false
	banner.visible = false
	shake = 0.0
	camera.offset = Vector2.ZERO
	_reset_powerups()
	_break_combo()
	_add_shake(16.0)
	Sfx.play("gameover", -2.0)
	if score > high_score:
		high_score = score
		_save_high_score()
	end_score.text = "SCORE  %d" % score
	end_best.text = "BEST  %d" % high_score
	end_overlay.visible = true
	retry_button.grab_focus()
	get_tree().paused = true

func _on_brick_destroyed(brick: Brick) -> void:
	remaining_bricks -= 1
	combo += 1
	var gained := brick.points * mini(combo, MAX_COMBO)
	_spawn_burst(brick.global_position, brick.base_color, 16, 320.0)
	_spawn_score_popup(brick.global_position, gained, brick.base_color)
	_add_score(gained)
	_update_combo()
	_add_shake(4.0)
	Sfx.play("break", -4.0, randf_range(0.92, 1.08))
	if randf() < 0.18:
		_spawn_power_up(brick.global_position)
	if remaining_bricks <= 0 and state == State.PLAYING:
		_level_cleared()

func _level_cleared() -> void:
	if state != State.PLAYING:
		return
	state = State.CLEARED
	hint.visible = false
	var bonus := 500 + level * 100
	_add_score(bonus)
	show_banner("LEVEL CLEARED  +%d" % bonus, Color(1.0, 0.85, 0.4), 1.7)
	Sfx.play("win", -2.0)
	get_tree().create_timer(1.8, false).timeout.connect(_advance_level)

func _advance_level() -> void:
	if not is_inside_tree() or state != State.CLEARED:
		return
	_clear_round()
	level += 1
	build_level(level)
	_spawn_ball()
	show_banner("LEVEL %d" % level, Color(0.55, 0.95, 1.0), 1.0)

func _clear_round() -> void:
	for b in active_balls:
		b.queue_free()
	active_balls.clear()
	_reset_powerups()
	_break_combo()

func apply_power_up(kind: String) -> void:
	if state == State.GAMEOVER:
		return
	Sfx.play("power", -3.0)
	_add_score(150)
	match kind:
		"wide":
			wide_time = 12.0
			paddle.target_width = WIDE_WIDTH
		"multi":
			_split_balls()
		"slow":
			slow_time = 8.0
			for b in active_balls:
				b.set_speed_multiplier(0.72)
		"shield":
			shield = true
			shield_line.visible = true
		"life":
			if lives < 5:
				lives += 1
				_update_hud()
			else:
				_add_score(300)
	var label: String = POWER_NAMES.get(kind, "POWER UP")
	show_banner(label, Color(0.6, 1.0, 0.75), 0.65)

func _split_balls() -> void:
	if state != State.PLAYING:
		return
	var current: Array[Ball] = active_balls.duplicate()
	for b in current:
		if b.stuck:
			continue
		var dir := b.velocity.normalized()
		if dir == Vector2.ZERO:
			continue
		for angle in [-0.45, 0.45]:
			if active_balls.size() >= 9:
				break
			var nb: Ball = BallScene.instantiate()
			balls.add_child(nb)
			nb.configure(paddle, b.speed, slow_time > 0.0)
			nb.global_position = b.global_position
			nb.launch(dir.rotated(angle))
			_track_ball(nb)

func _spawn_power_up(pos: Vector2) -> void:
	var powerup: PowerUp = PowerUpScene.instantiate()
	powerups.add_child(powerup)
	powerup.global_position = pos
	powerup.setup(_pick_power_type())

func _pick_power_type() -> String:
	var roll := randf()
	if roll < 0.34:
		return "wide"
	if roll < 0.58:
		return "multi"
	if roll < 0.78:
		return "slow"
	if roll < 0.92:
		return "shield"
	return "life"

func _spawn_score_popup(pos: Vector2, amount: int, tint: Color) -> void:
	var label := Label.new()
	label.text = "+%d" % amount
	label.position = pos + Vector2(-22.0, -26.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", tint)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	bursts.add_child(label)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 26.0, 0.5)
	tw.tween_property(label, "modulate:a", 0.0, 0.5)
	tw.chain().tween_callback(label.queue_free)

func _spawn_burst(pos: Vector2, color: Color, count: int, power: float) -> void:
	var burst := BurstScene.instantiate()
	bursts.add_child(burst)
	burst.setup(pos, color, count, power)

func _add_shake(amount: float) -> void:
	shake = minf(shake + amount, 20.0)

func _on_retry_pressed() -> void:
	get_tree().paused = false
	Sfx.play("click", -4.0)
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	Sfx.play("click", -4.0)
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _load_high_score() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SCORE_PATH) == OK:
		high_score = int(cfg.get_value("scores", "high", 0))

func _save_high_score() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "high", high_score)
	cfg.save(SCORE_PATH)
