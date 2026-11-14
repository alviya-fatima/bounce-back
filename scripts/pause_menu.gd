extends Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Panel/ResumeButton.pressed.connect(_on_resume)
	$Panel/RestartButton.pressed.connect(_on_restart)
	$Panel/MenuButton.pressed.connect(_on_menu)

func open() -> void:
	visible = true
	get_tree().paused = true
	$Panel/ResumeButton.grab_focus()

func close() -> void:
	visible = false
	get_tree().paused = false

func _on_resume() -> void:
	Sfx.play("click", -4.0)
	close()

func _on_restart() -> void:
	get_tree().paused = false
	Sfx.play("click", -4.0)
	get_tree().reload_current_scene()

func _on_menu() -> void:
	get_tree().paused = false
	Sfx.play("click", -4.0)
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		Sfx.play("click", -4.0)
		close()
		get_viewport().set_input_as_handled()
