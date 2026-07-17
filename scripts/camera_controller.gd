extends Camera2D

@export var pan_speed: float = 1100.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.2
@export var max_zoom: float = 5.0
@export var map_size: Vector2 = Vector2(2000, 2000)

@export var free_panning: bool = true   # wieder frei pannen können

var dragging := false
var last_mouse_pos := Vector2.ZERO

func _ready() -> void:
	position = map_size / 2.0
	zoom = Vector2(0.55, 0.55)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			last_mouse_pos = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_adjust_zoom(1.0 + zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_zoom(1.0 - zoom_speed)
	elif event is InputEventMouseMotion and dragging:
		var delta: Vector2 = event.position - last_mouse_pos
		position -= delta * (1.0 / zoom.x) * (pan_speed / 1000.0)
		last_mouse_pos = event.position
		if not free_panning:
			_clamp_camera()

func _adjust_zoom(factor: float) -> void:
	var new_zoom := zoom * factor
	new_zoom = new_zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
	zoom = new_zoom

func _clamp_camera() -> void:
	var viewport_size := get_viewport_rect().size
	var half_view := viewport_size / (2.0 * zoom)
	position.x = clamp(position.x, half_view.x, map_size.x - half_view.x)
	position.y = clamp(position.y, half_view.y, map_size.y - half_view.y)
