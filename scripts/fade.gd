extends ColorRect

func _ready() -> void:
	color.a = 1.0
	var tw := create_tween()
	tw.tween_property(self, "color:a", 0.0, 0.45)
	tw.tween_callback(hide)
